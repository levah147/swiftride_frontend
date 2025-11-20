// ==================== main_navigation_screen.dart ====================
// THEME-AWARE MAIN NAVIGATION SCREEN
// Supports both Rider and Driver modes with theme adaptation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';
import '../../services/driver_service.dart';
import '../main/home_screen.dart';
import '../rides/rides_screen.dart';
import '../../presentation/screens/account/account_screen.dart';

import '../drivers/driver_earnings_screen.dart';
import '../drivers/driver_rides_screen.dart';
// import '../drivers/driver_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final DriverService _driverService = DriverService();
  
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isDriver = false;
  bool _isApproved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkUserRole();
  }

  // ============================================
  // CHECK USER ROLE (RIDER OR DRIVER)
  // ============================================

//
Future<void> _checkUserRole() async {
  try {
    final response = await _driverService.getDriverStatus();
    
    if (!mounted) return;
    
    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      
      // Check if user is a driver
      if (data.containsKey('is_driver') && data['is_driver'] == false) {
        // User is not a driver
        setState(() {
          _isDriver = false;
          _isApproved = false;
          _isLoading = false;
          _initializeRiderScreens();
        });
        return;
      }
      
      // ✅ FIX: Check for status INSIDE the 'driver' object
      if (data.containsKey('driver') && data['driver'] != null) {
        final driverData = data['driver'] as Map<String, dynamic>;
        
        if (driverData.containsKey('status')) {
          final status = driverData['status'] as String;
          final isApproved = status.toLowerCase() == 'approved';
          
          setState(() {
            _isDriver = true;
            _isApproved = isApproved;
            _isLoading = false;
            _initializeDriverScreens();
          });
          
          // Show approval notification if just approved
          if (isApproved) {
            _showApprovalModal();
          }
          return;
        }
      }
      
      // If we get here, treat as non-driver
      setState(() {
        _isDriver = false;
        _isApproved = false;
        _isLoading = false;
        _initializeRiderScreens();
      });
    } else {
      setState(() {
        _isDriver = false;
        _isApproved = false;
        _isLoading = false;
        _initializeRiderScreens();
      });
    }
  } catch (e) {
    debugPrint('Error checking user role: $e');
    setState(() {
      _isDriver = false;
      _isApproved = false;
      _isLoading = false;
      _initializeRiderScreens();
    });
  }
}

  // ============================================
  // INITIALIZE SCREENS
  // ============================================

  void _initializeRiderScreens() {
    _screens = [
      HomeScreen(onNavigate: _handleNavigation),
      RidesScreen(onNavigate: _handleNavigation),
      AccountScreen(onNavigate: _handleNavigation),
    ];
  }

  void _initializeDriverScreens() {
    _screens = [
      const DriverEarningsScreen(),
      const DriverRidesScreen(),
      // DriverProfileScreen(onNavigate: _handleNavigation),
      AccountScreen(onNavigate: _handleNavigation), // ✅ UNIFIED
    ];
    _currentIndex = 0;
  }

  // ============================================
  // APPROVAL MODAL
  // ============================================

  void _showApprovalModal() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: isDark 
              ? colorScheme.surface 
              : colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Congratulations! 🎉',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You\'ve been approved as a driver!',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can now accept ride requests and start earning',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Driver Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================
  // NAVIGATION HANDLER
  // ============================================

  void _handleNavigation(String action, {Map<String, dynamic>? data}) {
    switch (action) {
      case 'destination_selection':
        Navigator.of(context).pushNamed(AppRoutes.destinationSelection);
        break;

      case 'schedule_ride':
        Navigator.of(context).pushNamed(AppRoutes.destinationSelection);
        break;

      case 'logout':
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
        break;

      default:
        break;
    }
  }

  void _onNavbarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Update system UI based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    // ============================================
    // LOADING STATE
    // ============================================
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    // ============================================
    // RIDER NAVIGATION
    // ============================================
    if (!_isDriver) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: isDark 
                ? colorScheme.surface 
                : colorScheme.surface,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant,
            onTap: _onNavbarTap,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Rides',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),
      );
    }

    // ============================================
    // DRIVER NAVIGATION (APPROVED)
    // ============================================
    if (_isDriver && _isApproved) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: isDark 
                ? colorScheme.surface 
                : colorScheme.surface,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant,
            onTap: _onNavbarTap,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up_outlined),
                activeIcon: Icon(Icons.trending_up),
                label: 'Earnings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car_outlined),
                activeIcon: Icon(Icons.directions_car),
                label: 'Rides',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),
      );
    }

    // ============================================
    // DRIVER PENDING APPROVAL (ACCOUNT ONLY)
    // ============================================
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: 2, // Always show account screen
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: isDark 
              ? colorScheme.surface 
              : colorScheme.surface,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          currentIndex: 2,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          onTap: (index) {
            if (index == 2) {
              setState(() => _currentIndex = 2);
            }
          },
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Rides',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}