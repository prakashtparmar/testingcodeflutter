import 'package:flutter/material.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:snap_check/services/auth_service.dart';
import 'package:snap_check/services/share_pref.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  String? _token;
  String? _email;
  String? _name;
  bool _isLoading = false;
  final List<_SettingItem> _settings = [
    // _SettingItem(
    //   icon: Icons.account_circle_outlined,
    //   title: 'Account',
    //   onTapMessage: 'Account tapped',
    // ),
    // _SettingItem(
    //   icon: Icons.security,
    //   title: 'Privacy & Security',
    //   onTapMessage: 'Privacy tapped',
    // ),
    // _SettingItem(
    //   icon: Icons.notifications_active_outlined,
    //   title: 'Notifications',
    //   onTapMessage: 'Notifications tapped',
    // ),
    // _SettingItem(
    //   icon: Icons.language,
    //   title: 'Language',
    //   onTapMessage: 'Language tapped',
    // ),
    _SettingItem(
      icon: Icons.security,
      title: 'Change Password',
      onTapMessage: 'Change Password tapped',
      route: "/changePassword",
    ),
    _SettingItem(
      icon: Icons.logout,
      title: 'Logout',
      onTapMessage: 'Logout tapped',
      isLogout: true,
      route: "/",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _navigationRoutes(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  Future<void> _loadUser() async {
    final userData = await SharedPrefHelper.loadUser();
    final tokenData = await SharedPrefHelper.getToken();

    setState(() {
      _user = userData;
      _token = tokenData ?? "";
      _email = userData?.email ?? "";
      _name = userData?.getName().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_user != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _name ?? "",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'View Profile',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/userDetail',
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Profile',
                                    onPressed: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/editProfile',
                                      );
                                      if (result == true) {
                                        _loadUser(); // Refresh if edited
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                _email ?? "",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: ListView.separated(
                      itemCount: _settings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _settings[index];
                        return GestureDetector(
                          onTap: () {
                            item.isLogout
                                ? _confirmLogout(context)
                                : _navigationRoutes(context, item.route);
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                item.icon,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

  void _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (_token != null && _token!.isNotEmpty) {
        setState(() => _isLoading = true);
        var result = await AuthService().signOut(
          _token ?? "",
        ); // Call your logout logic
        debugPrint("result $result");
        setState(() => _isLoading = false);
      }
      SharedPrefHelper.clearUser();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String onTapMessage;
  final String route;
  final bool isLogout;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.onTapMessage,
    required this.route,
    this.isLogout = false,
  });
}
