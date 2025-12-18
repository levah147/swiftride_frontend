
# 🔍 FRONTEND-BACKEND INTEGRATION ANALYSIS

## **CRITICAL API CONTRACT MISMATCHES** 🚨

### **1. Vehicle Types Endpoint Mismatch**

**Frontend**: `pricing_service.dart` line 27

```dart
'/pricing/types/',  // ❌ WRONG
```

**Backend**: `pricing/urls.py` line 15

```python
path('vehicle-types/', views.get_available_vehicles, name='vehicle_types'),  # ✅ CORRECT
```

**Issue**: Frontend uses `/pricing/types/` but backend expects `/pricing/vehicle-types/`

**Fix**: Change line 27 in `pricing_service.dart`:

```dart
'/pricing/vehicle-types/',  // ✅ FIXED
```

---

### **2. Ride Creation Missing Fields**

**Frontend**: `ride_service.dart` line 39

```dart
final data = {
  'vehicle_type': vehicleType,  // ✅ Good
  'pickup_location': pickupLocation,
  // ... other fields
  'fare_hash': fareHash,  // ✅ Good
  'ride_type': scheduledTime != null ? 'scheduled' : 'immediate',
  if (cityName != null) 'city_name': cityName,
};
```

**Backend**: `rides/views.py` line 71 expects:

```python
vehicle_type_id = fare_data.get('vehicle_type_id')  # ❌ Expects vehicle_type_id
city_id = fare_data.get('city_id')  # ❌ Expects city_id
```

**Problem**: Frontend sends `vehicle_type` (string) but backend expects `vehicle_type_id`. Backend expects `city_id` but frontend sends `city_name`.

**Fix Needed**: Either:

1. Backend should accept `vehicle_type` and `city_name` (RECOMMENDED)
2. Frontend should send IDs instead of names

---

### **3. Pricing Calculate Fare Response Mismatch**

**Frontend**: `pricing_service.dart` line 101

```dart
class FareCalculation {
  final String fareHash;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double fuelAdjustment;
  final double totalFare;
  final double distance;  // ❌ Field name mismatch
  final int estimatedDuration;  // ❌ Field name mismatch
}
```

**Backend**: `pricing/views.py` line 252 returns:

```python
{
    'distance_km': ...,  # ✅ Backend uses distance_km
    'estimated_duration_minutes': ...,  # ✅ Backend uses estimated_duration_minutes
}
```

**Fix**: Update `FareCalculation.fromJson`:

```dart
distance: _parseDouble(json['distance_km']) ?? 0.0,  // ✅ FIXED
estimatedDuration: json['estimated_duration_minutes'] ?? 0,  // ✅ FIXED
```

---

### **4. Driver Available Rides Endpoint Missing**

**Frontend**: `driver_service.dart` line 52

```dart
'/rides/available/',  // ❌ Used by frontend
```

**Backend**: `rides/urls.py` - **ENDPOINT EXISTS** ✅

```python
path('available/', views.available_rides, name='available-rides'),  # Line 11
```

**But**: Backend returns `RideRequest` objects, not simplified ride data

**Backend**: `rides/views.py` line 138 returns:

```python
serializer = AvailableRideSerializer(ride_requests, many=True)
```

**Frontend expects**: `driver_service.dart` line 63

```dart
DriverAvailableRide.fromJson(e as Map<String, dynamic>)
```

**Issue**: Field name mismatches between `AvailableRideSerializer` and `DriverAvailableRide`

---

### **5. WebSocket Connection Missing Token Parameter**

**Frontend**: `driver_matching_screen.dart` line 41

```dart
await socketService.connectToRide(widget.rideId, token);
```

**Backend**: `rides/consumers.py` line 27

```python
token = self.scope['query_string'].decode().split('token=')[1]  # ❌ Expects ?token=xxx
```

**Problem**: If `SocketService` doesn't append `?token=` to URL, backend crashes

**Check**: Does `socket_service.dart` properly format WebSocket URL with `?token=`?

---

### **6. Ride Status Enum Mismatch**

**Frontend**: `ride.dart` line 3-9

```dart
enum RideStatus {
  pending,
  driverAssigned,  // ❌ camelCase
  driverArriving,  // ❌ camelCase
  inProgress,      // ❌ camelCase
  completed,
  cancelled;
}
```

**Backend**: `rides/models.py` line 12

```python
RIDE_STATUS_CHOICES = [
    ('pending', 'Pending'),
    ('accepted', 'Accepted'),  # ❌ Backend uses 'accepted' not 'driver_assigned'
    ('arriving', 'Driver Arriving'),  # ❌ Backend uses 'arriving'
    ('in_progress', 'In Progress'),  # ❌ Backend uses 'in_progress' with underscore
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
]
```

**Fix**: Update `RideStatus.fromString` in `ride.dart`:

```dart
static RideStatus fromString(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return RideStatus.pending;
    case 'accepted':  // ✅ Backend sends 'accepted'
    case 'driver_assigned':
      return RideStatus.driverAssigned;
    case 'arriving':  // ✅ Backend sends 'arriving'
    case 'driver_arriving':
      return RideStatus.driverArriving;
    case 'in_progress':  // ✅ Backend sends 'in_progress'
      return RideStatus.inProgress;
    // ...
  }
}
```

---

### **7. Driver Model Structure Mismatch**

**Frontend**: `ride.dart` line 97

```dart
class Driver {
  final String id;
  final String name;  // ❌ Frontend expects 'name'
  final String phoneNumber;  // ❌ Frontend expects camelCase
  final double rating;
  final String vehicleModel;  // ❌ Frontend expects 'vehicleModel'
  final String vehicleColor;
  final String licensePlate;
}
```

**Backend**: `rides/serializers.py` line 7 returns:

```python
class RideSerializer(serializers.ModelSerializer):
    driver_name = serializers.SerializerMethodField()  # ✅ Backend uses snake_case
    driver_phone = serializers.SerializerMethodField()
    vehicle_info = serializers.SerializerMethodField()  # ❌ Combined string, not individual fields
```

**Problem**: Backend returns `driver_name`, `driver_phone`, `vehicle_info` as strings, but frontend expects structured `Driver` object with separate `vehicleModel`, `vehicleColor`, `licensePlate`

**Fix Required**: Update backend serializer OR frontend model to match

---

### **8. Ride Tracking Screen Missing Initial Data Load**

**Frontend**: `ride_tracking_screen.dart` line 49

```dart
Future<void> _loadInitialRideData() async {
  // Fetches ride details from /api/rides/{id}/
  final response = await _rideService.getRideDetails(widget.rideId);
}
```

**Backend**: `rides/urls.py` - **MISSING ENDPOINT** ❌

```python
# ❌ NO endpoint for GET /api/rides/{id}/
# Only has:
path('', views.RideListCreateView.as_view(), name='ride-list-create'),  # List & Create
path('<int:pk>/', views.RideDetailView.as_view(), name='ride-detail'),  # But uses 'pk' not 'rideId'
```

**Issue**: Endpoint exists but uses `pk` (integer) while frontend might send string ID

---

### **9. Document Upload Field Names**

**Frontend**: `driver_service.dart` line 124

```dart
Future<ApiResponse<Map<String, dynamic>>> uploadVerificationDocument({
  required String documentType,
  required String filePath,
}) async {
  return await _apiClient.postMultipart<Map<String, dynamic>>(
    '/drivers/upload-document/',
    {
      'document_type': documentType,  // ✅ Good
    },
    {
      'document': filePath,  // ✅ Good
    },
  );
}
```

**Backend**: `drivers/views.py` line 290

```python
document_type = request.data.get('document_type')  # ✅ Matches
document_file = request.FILES.get('document')  # ✅ Matches
```

**Status**: ✅ **CORRECT** - No mismatch

---

### **10. Vehicle Image Upload Location Mismatch**

**Frontend**: `driver_service.dart` line 142

```dart
'/drivers/upload-vehicle-image/',  // ❌ WRONG - uploads to drivers app
```

**Backend Reality**: Vehicle images should go to `vehicles` app, not `drivers` app

**Backend**: `drivers/views.py` line 332 has the endpoint but it's wrong (uses old `VehicleImage` model linked to driver)

**Critical**: This is the **VehicleImage architectural issue** we identified earlier!

---

## **MISSING BACKEND ENDPOINTS NEEDED BY FRONTEND** ⚠️

### **11. Ride Receipt Endpoint**

**Frontend**: `ride_service.dart` line 185

```dart
'/rides/$rideId/receipt/',  // ❌ Frontend expects this
```

**Backend**: `rides/urls.py` - **DOES NOT EXIST** ❌

---

### **12. Driver Location Endpoint**

**Frontend**: `ride_service.dart` line 168

```dart
'/rides/$rideId/driver-location/',  // ❌ Frontend expects this
```

**Backend**: `rides/urls.py` - **DOES NOT EXIST** ❌

---

### **13. Ride Rating GET Endpoint**

**Frontend**: `ride_service.dart` line 154

```dart
Future<ApiResponse<Map<String, dynamic>>> getRideRating(String rideId) async {
  return await _apiClient.get<Map<String, dynamic>>(
    '/rides/$rideId/rating/',  // ❌ GET request
  );
}
```

**Backend**: `rides/urls.py` line 8

```python
path('<int:ride_id>/rate/', views.rate_ride, name='rate-ride'),  # ❌ Only POST, no GET
```

---

## **WEBSOCKET ISSUES** 🔌

### **14. WebSocket URL Format**

**Frontend**: `api_config.dart` line 30

```dart
static const String _localWsUrl = 'ws://192.168.229.65:8000/ws';
```

**Backend**: `rides/routing.py` line 9

```python
path('ws/ride/<int:ride_id>/', consumers.RideConsumer.as_asgi()),
```

**Expected URL**: `ws://192.168.229.65:8000/ws/ride/123/?token=xxx`

**Issue**: Frontend must construct: `${wsUrl}/ride/${rideId}/?token=${token}`

---

### **15. WebSocket Message Format Mismatch**

**Frontend** expects: `driver_matching_screen.dart` line 71

```dart
_driverMatchSubscription = socketService.driverMatchStream.listen(
  (match) {
    // Expects DriverMatch object with:
    // - driverId
    // - driverName
    // - driverPhone
    // - driverRating
    // - vehicleType
    // - vehicleModel
    // - vehicleColor
    // - licensePlate
  },
);
```

**Backend** sends: `rides/consumers.py` line 88

```python
{
    'type': 'driver_matched_update',
    'driver_id': str(driver.id),
    'driver_name': driver.user.get_full_name() or driver.user.phone_number,
    'vehicle_type': vehicle.vehicle_type.name if vehicle and hasattr(vehicle, 'vehicle_type') else 'Unknown',
    'vehicle_model': f"{vehicle.make} {vehicle.model}" if vehicle else 'Unknown',
    'vehicle_color': vehicle.color if vehicle else 'Unknown',
    'license_plate': vehicle.license_plate if vehicle else 'Unknown',
    'eta_minutes': 5,
}
```

**Issue**: Backend doesn't send:

- `driver_phone` ❌
- `driver_rating` ❌
- Sends `eta_minutes` but frontend might not expect it

---

## **FIELD NAME CONVENTION MISMATCHES** 📋

### **16. Snake_case vs camelCase**

**Pattern**: Backend uses `snake_case`, Frontend uses `camelCase`

**Examples**:

- Backend: `driver_name` → Frontend: `driverName`
- Backend: `pickup_location` → Frontend: `pickupLocation`
- Backend: `vehicle_type` → Frontend: `vehicleType`

**Solution**: Frontend models handle conversion in `fromJson`, but **must be consistent**

---

## **AUTHENTICATION ISSUES** 🔐

### **17. Token Storage Keys**

**Frontend**: `api_client.dart` line 27

```dart
prefs.getString('access_token');
prefs.getString('refresh_token');
```

**Backend** returns: `accounts/views.py` (OTP verification)

```python
{
    "tokens": {
        "access": "...",
        "refresh": "..."
    }
}
```

**Frontend**: `api_client.dart` line 396 handles this correctly ✅

---

## **SUMMARY OF REQUIRED FIXES**

| Issue | Location | Priority | Fix Required |
|-------|----------|----------|--------------|
| 1. Vehicle types endpoint | `pricing_service.dart:27` | 🚨 CRITICAL | Change to `/pricing/vehicle-types/` |
| 2. Ride creation fields | `ride_service.dart:39` | 🚨 CRITICAL | Match backend expected fields |
| 3. Fare calculation response | `pricing_service.dart:101` | 🚨 CRITICAL | Use `distance_km`, `estimated_duration_minutes` |
| 4. Available rides serializer | Backend | 🚨 CRITICAL | Ensure field names match `DriverAvailableRide` |
| 5. WebSocket token format | `driver_matching_screen.dart:41` | 🚨 CRITICAL | Verify `?token=` appended |
| 6. Ride status enum | `ride.dart:3` | 🚨 CRITICAL | Accept `accepted`, `arriving`, `in_progress` |
| 7. Driver model structure | Backend | 🔥 HIGH | Send structured driver object, not strings |
| 8. Ride detail endpoint | Backend | 🔥 HIGH | Verify `<int:pk>` works with string IDs |
| 9. VehicleImage upload | Both | 🔥 HIGH | Fix architectural issue |
| 10. Missing endpoints | Backend | ⚠️ MEDIUM | Add receipt, driver location, rating GET |
| 11. WebSocket message format | Backend | ⚠️ MEDIUM | Add `driver_phone`, `driver_rating` |
