import 'package:flutter/material.dart';
import 'package:snap_check/constants/constants.dart';
import 'package:snap_check/models/active_day_log_data_model.dart';
import 'package:snap_check/models/active_day_log_response_model.dart';
import 'package:snap_check/screens/setting_screen.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/locations/new_location_service.dart';
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
  final locationService = NewLocationService();
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
    final hasPreciseLocationPermission =
        await permissionHandler.hasPreciseLocationPermission;
    if (!hasLocationPermission || !hasPreciseLocationPermission) {
      if (!hasLocationPermission) {
        bool granted = await permissionHandler.requestLocationPermission();
        if (granted) {
          debugPrint("User granted location permission");
          // Proceed with location-related tasks
        } else {
          debugPrint("User denied location permission");
          // Show a message or open app settings
        }
      }
      if (!hasPreciseLocationPermission) {
        bool granted =
            await permissionHandler.requestPreciseLocationPermission();
        if (granted) {
          debugPrint("User granted Precise location permission");
          // Proceed with location-related tasks
        } else {
          debugPrint("User denied Precise location permission");
          // Show a message or open app settings
        }
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
  }

  Future<void> _fetchActiveDayLog() async {
    if (!mounted) return; // Early return if widget is not mounted

    setState(() => _isLoading = true);

    try {
      final tokenData = await SharedPrefHelper.getToken();
      if (tokenData == null) {
        _redirectToLogin();
        return;
      }

      final response = await _basicService.getActiveDayLog(tokenData);
      debugPrint("Active day log response: ${response?.message}");

      if (response != null && response.data != null) {
        // Case: Active day log exists
        await _handleActiveDayLogFound(response, tokenData);
      } else {
        // Case: No active day log
        await _handleNoActiveDayLog();
      }
    } catch (e) {
      await _handleFetchError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleActiveDayLogFound(
    ActiveDayLogResponseModel response,
    String tokenData,
  ) async {
    final dayLogId = response.data!.id.toString();
    await SharedPrefHelper.saveActiveDayLogId(dayLogId);
    SharedPrefHelper.setTrackingActive(true);
    if (mounted) {
      setState(() {
        _activeDayLogDataModel = response.data;
      });
    }

    // Start tracking if not already tracking
    if (locationService.isTracking) {
      debugPrint("Tracking already active");
    } else {
      debugPrint("Starting location tracking...");
      final started = await locationService.startTracking(
        token: tokenData,
        dayLogId: dayLogId,
      );
      debugPrint("Tracking started: $started");

      if (!started) {
        // Handle tracking start failure
        debugPrint("Failed to start tracking");
        // You might want to show an error to the user here
      }
    }
  }

  Future<void> _handleNoActiveDayLog() async {
    if (mounted) {
      setState(() {
        _activeDayLogDataModel = null;
      });
    }

    // Stop any existing tracking
    await _stopTrackingServices();
    SharedPrefHelper.setTrackingActive(false);
    await SharedPrefHelper.clearActiveDayLog();
  }

  Future<void> _handleFetchError(dynamic e) async {
    debugPrint("Error fetching active day log: $e");

    if (e is UnauthorizedException) {
      await _stopTrackingServices();
      SharedPrefHelper.clearUser();
      _redirectToLogin();
    } else if (e is NotFoundException) {
      await _stopTrackingServices();
      await SharedPrefHelper.clearActiveDayLog();

      if (mounted) {
        setState(() {
          _activeDayLogDataModel = null;
        });
      }
    }
    // Other errors are silently caught (you might want to show a snackbar)
  }

  Future<void> _stopTrackingServices() async {
    try {
      debugPrint("Stopping tracking services...");
      await locationService.stopTracking();
      // await locationService.dispose();
      debugPrint("Tracking services stopped successfully");
    } catch (e) {
      debugPrint("Error stopping tracking services: $e");
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
                            _navigationRoutes(context, "/starTrip", true);
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
                            _navigationRoutes(context, "/dayLogs", true);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: AppAssets.leaves,
                          title: "Leaves",
                          onTap: () {
                            _navigationRoutes(context, "/leaves", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .budgetPlan, // Make sure to add this asset
                          title: "Budget Plan",
                          onTap: () {
                            _navigationRoutes(context, "/budgetPlan", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .monthlyPlan, // Make sure to add this asset
                          title: "Monthly Plan",
                          onTap: () {
                            _navigationRoutes(context, "/monthlyPlan", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .paymentCollection, // Make sure to add this asset
                          title: "Payment Collection",
                          onTap: () {
                            _navigationRoutes(
                              context,
                              "/paymentCollection",
                              false,
                            );
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: AppAssets.order, // Make sure to add this asset
                          title: "Order",
                          onTap: () {
                            _navigationRoutes(context, "/order", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .partyVisit, // Make sure to add this asset
                          title: "Party Visit",
                          onTap: () {
                            _navigationRoutes(context, "/partyVisit", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .partyStatement, // Make sure to add this asset
                          title: "Party Statement",
                          onTap: () {
                            _navigationRoutes(
                              context,
                              "/partyStatement",
                              false,
                            );
                          },
                        ),

                        _buildGridItem(
                          context,
                          icon:
                              AppAssets
                                  .dayReport, // Make sure to add this asset
                          title: "Day Report",
                          onTap: () {
                            _navigationRoutes(context, "/dayReport", false);
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: AppAssets.stock, // Make sure to add this asset
                          title: "Stock",
                          onTap: () {
                            _navigationRoutes(context, "/stock", false);
                          },
                        ),
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
  void _navigationRoutes(BuildContext context, String routeName, bool isExit) {
    if (isExit) {
      Navigator.pushNamed(context, routeName);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Coming soon!")));
    }
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
