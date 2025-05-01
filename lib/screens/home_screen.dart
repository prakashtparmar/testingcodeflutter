import 'package:flutter/material.dart';
import 'package:snap_check/screens/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                _showSnackBar(context, "User icon tapped");
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, color: Colors.black87),
              ),
            ),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select an option below to proceed",
                  style: Theme.of(context).textTheme.bodyLarge,
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
                      icon: Icons.calendar_view_day,
                      title: "Day Logs",
                      onTap: () {
                        _showSnackBar(context, "Profile tapped");
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: "Settings",
                      onTap: () {
                        _showSnackBar(context, "Settings tapped");
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: "Notifications",
                      onTap: () {
                        _showSnackBar(context, "Notifications tapped");
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.help_outline,
                      title: "Help",
                      onTap: () {
                        _showSnackBar(context, "Help tapped");
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.info_outline,
                      title: "About",
                      onTap: () {
                        _showSnackBar(context, "About tapped");
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.feedback_outlined,
                      title: "Feedback",
                      onTap: () {
                        _showSnackBar(context, "Feedback tapped");
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

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
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
