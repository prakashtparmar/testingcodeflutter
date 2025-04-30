import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ), // Accessing the title from the StatefulWidget
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap the Column in SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to the Home Screen",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
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
                  crossAxisCount: 3, // Now using 3 columns
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1, // Equal size for each grid item
                  children: [
                    _buildGridItem(
                      context,
                      icon: Icons.account_circle_outlined,
                      title: "Profile",
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
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
