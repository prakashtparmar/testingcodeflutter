import 'package:flutter/material.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:snap_check/services/auth_service.dart';
import 'package:snap_check/services/share_pref.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _fetchUserDetail();
  }

  Future<void> _loadUser() async {
    final tokenData = await SharedPrefHelper.getToken();
    debugPrint(tokenData);
    setState(() {
      _token = tokenData ?? "";
    });
  }

  Future<void> _fetchUserDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await _authService.fetchUserDetail(_token!);
      debugPrint(response?.message);
      setState(() {
        _user = response!.data!.user;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body:
          _isLoading || _user == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: (0.2 * 255),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${_user?.firstName ?? ''} ${_user?.lastName ?? ''}"
                              .trim()
                              .isEmpty
                          ? ""
                          : "${_user?.firstName ?? ''} ${_user?.lastName ?? ''}",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: colorScheme.outlineVariant),
                    _buildDetailRow(
                      context,
                      icon: Icons.location_on,
                      label: "Address Line 1",
                      value: _user!.addressLine1 ?? "",
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.location_on,
                      label: "Address Line 2",
                      value: _user!.addressLine2 ?? "",
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.location_city,
                      label: "City",
                      value: _user!.city?.name ?? "",
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.landscape,
                      label: "State",
                      value: _user!.state?.name ?? "",
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.flag,
                      label: "Country",
                      value: _user!.country?.name ?? "",
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
