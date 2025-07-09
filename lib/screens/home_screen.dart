import 'package:flutter/material.dart';
import 'package:snap_check/constants/constants.dart';
import 'package:snap_check/models/active_day_log_data_model.dart';
import 'package:snap_check/screens/setting_screen.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/location_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:snap_check/utils/permission_uril.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BasicService _basicService = BasicService();
  ActiveDayLogDataModel? _activeDayLogDataModel = null;
  final permissionHandler = PermissionUtil();
  final locationService = LocationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchActiveDayLog();
    }
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    // Initialize background service
    // Check and request notification permission
    if (await permissionHandler.isNotificationPermissionRequired) {
      final hasPermission =
          await permissionHandler.requestNotificationPermission();
      if (!hasPermission) {
        // Handle permission denial
        debugPrint('Notification permission denied');
        // Optionally show user guidance
      }
    }
    final hasLocationPermission = await permissionHandler.hasLocationPermission;
    if (!hasLocationPermission) {
      bool granted = await permissionHandler.requestLocationPermission();
      if (granted) {
        debugPrint("User granted location permission");
        // Proceed with location-related tasks
      } else {
        debugPrint("User denied location permission");
        // Show a message or open app settings
      }
      // Optionally show user guidance
    }
    bool isLocationEnabled = await permissionHandler.areLocationServicesEnabled;
    if (isLocationEnabled) {
      debugPrint("Location services (GPS) are on");
    } else {
      debugPrint("Please enable GPS/Location services");
      bool preciseGranted =
          await permissionHandler.requestPreciseLocationPermission();
      if (preciseGranted) {
        debugPrint("Precise location access granted");
      } else {
        debugPrint("Only approximate location available");
      }
    }
    await _fetchActiveDayLog();
  }

  Future<void> _fetchActiveDayLog() async {
    final tokenData = await SharedPrefHelper.getToken();
    try {
      setState(() => _isLoading = true);

      final response = await _basicService.getActiveDayLog(tokenData!);
      debugPrint("response ${response?.message}");
      if (response != null && response.data != null) {
        SharedPrefHelper.saveActiveDayLogId(response.data!.id.toString());
        setState(() {
          _activeDayLogDataModel = response.data;
        });

        // Start tracking
        bool started = await locationService.startTracking(
          token: tokenData,
          dayLogId: "${response.data?.id}",
        );
        debugPrint("started $started");
      } else {
        _activeDayLogDataModel = null;

        // Stop tracking
        await locationService.stopTracking();
        await locationService.forceStopAllServices();
        // Dispose when done
        await locationService.dispose();
        SharedPrefHelper.clearActiveDayLog();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (e is UnauthorizedException) {
        _activeDayLogDataModel = null;
        setState(() {
          _isLoading = false;
        });
        SharedPrefHelper.clearUser();
        _redirectToLogin();
      } else if (e is NotFoundException) {
        _activeDayLogDataModel = null;
        // Stop tracking
        await locationService.stopTracking();
        await locationService.forceStopAllServices();
        // Dispose when done
        await locationService.dispose();

        setState(() {
          _isLoading = false;
        });
        SharedPrefHelper.clearActiveDayLog();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _redirectToCheckout() {
    Navigator.of(context)
        .pushNamed('/checkoutDayLog', arguments: _activeDayLogDataModel)
        .then((flag) {
          if (flag == true) {
            _fetchActiveDayLog();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              // Wrap the Column in SingleChildScrollView
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Select an option below to proceed",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Full-width Check-In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check_circle_rounded),
                        label: Text(
                          _activeDayLogDataModel == null
                              ? "Check In / Start Day Log"
                              : "Stop Tracking",
                        ),
                        onPressed: () {
                          if (_activeDayLogDataModel == null) {
                            _navigationRoutes(context, "/starTrip");
                          } else {
                            _redirectToCheckout();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Using shrinkWrap and setting the GridView to take only available space
                    GridView.count(
                      shrinkWrap:
                          true, // Ensures the GridView only takes as much space as it needs
                      physics:
                          NeverScrollableScrollPhysics(), // Disables scrolling in the GridView
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1, // Equal size for each grid item
                      children: [
                        _buildGridItem(
                          context,
                          icon: AppAssets.dayLogs,
                          title: "Day Logs",
                          onTap: () {
                            _navigationRoutes(context, "/dayLogs");
                          },
                        ),
                        // _buildGridItem(
                        //   context,
                        //   icon: AppAssets.leaves,
                        //   title: "Leaves",
                        //   onTap: () {
                        //     _navigationRoutes(context, "/leaves");
                        //   },
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // Function to show SnackBar
  void _navigationRoutes(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Container(
          // padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, width: 50, height: 50),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
