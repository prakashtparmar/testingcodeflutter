import 'package:flutter/material.dart';
import 'package:snap_check/constants/constants.dart';
import 'package:snap_check/screens/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;

    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Select an option below to proceed",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                // Full-width Check-In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_rounded),
                    label: Text("Check In / Add Day Log"),
                    onPressed: () {
                      _navigationRoutes(context, "/addDayLog");
                    },
                  ),
                ),

                const SizedBox(height: 32),
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
                    _buildGridItem(
                      context,
                      icon: AppAssets.leaves,
                      title: "Leaves",
                      onTap: () {
                        _navigationRoutes(context, "/leaves");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to show SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
