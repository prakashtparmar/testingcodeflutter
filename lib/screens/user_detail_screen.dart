import 'package:flutter/material.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:snap_check/services/api_exception.dart';
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
      setState(() {
        _user = response!.data!.user;
      });
    } on UnauthorizedException {
      SharedPrefHelper.clearUser();
      _redirectToLogin();
    } on NotFoundException {
      _showError('User not found.');
    } on ServerErrorException {
      _showError('Server error. Try again later.');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Something went wrong. $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  String _getFullAddress() {
    List<String?> parts =
        [
          _user?.addressLine1,
          _user?.addressLine2,
          _user?.taluka?.name,
          _user?.city?.name,
          _user?.state?.name,
          _user?.country?.name,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();

    return parts.join(', ');
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ---------- PROFILE CARD ----------
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.15,
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
                                  .trim(),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _user!.email ?? '',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------- INFO CARD ----------
                    Text(
                      "User Information",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            _infoRow(
                              icon: Icons.supervised_user_circle,
                              title: "Designation",
                              value: _user?.designation?.name ?? 'N/A',
                            ),
                            const Divider(height: 30),
                            _infoRow(
                              icon: Icons.verified_user,
                              title: "Manager",
                              value:
                                  "${_user?.manager?.firstName ?? ''} ${_user?.manager?.lastName ?? ''}"
                                      .trim(),
                            ),
                            const Divider(height: 30),
                            _infoRow(
                              icon: Icons.wc,
                              title: "Gender",
                              value: _user?.gender ?? 'N/A',
                            ),
                            const Divider(height: 30),
                            _infoRow(
                              icon: Icons.location_on,
                              title: "Full Address",
                              value: _getFullAddress(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : "N/A",
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
