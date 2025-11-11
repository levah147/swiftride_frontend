import '../models/location.dart';
import 'api_client.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ApiResponse<List<SavedLocation>>> getSavedLocations() async {
    return await _apiClient.get<List<SavedLocation>>(
      '/locations/saved/',
      fromJson: (json) => (json as List).map((item) => SavedLocation.fromJson(item)).toList(),
    );
  }

  Future<ApiResponse<SavedLocation>> addSavedLocation(SavedLocation location) async {
    return await _apiClient.post<SavedLocation>(
      '/locations/saved/',
      location.toJson(),
      fromJson: (json) => SavedLocation.fromJson(json),
    );
  }

  Future<ApiResponse<SavedLocation>> updateSavedLocation(
    String locationId,
    SavedLocation location,
  ) async {
    return await _apiClient.put<SavedLocation>(
      '/locations/saved/$locationId/',
      location.toJson(),
      fromJson: (json) => SavedLocation.fromJson(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteSavedLocation(String locationId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      '/locations/saved/$locationId/',
    );
  }

  Future<ApiResponse<List<RecentLocation>>> getRecentLocations() async {
    return await _apiClient.get<List<RecentLocation>>(
      '/locations/recent/',
      fromJson: (json) => (json as List).map((item) => RecentLocation.fromJson(item)).toList(),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addRecentLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/locations/recent/',
      {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}
