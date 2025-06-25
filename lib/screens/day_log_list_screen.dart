import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:connectivity_plus/connectivity_plus.dart'; // For network checking
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/screens/live_map_screen.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

class DayLogsListScreen extends StatefulWidget {
  const DayLogsListScreen({super.key});

  @override
  State<DayLogsListScreen> createState() => _DayLogsListScreenState();
}

class _DayLogsListScreenState extends State<DayLogsListScreen> {
  // Services and Controllers
  final BasicService _service = BasicService();
  final TextEditingController _searchController = TextEditingController();

  // Data State
  List<DayLogsDataModel> _allLogs = [];
  List<DayLogsDataModel> _filteredLogs = [];
  String? _token;
  String? _error;

  // UI State
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterLogs);
  }

  // Initialize essential data and check connectivity
  Future<void> _initializeData() async {
    await _loadToken();
    await _checkConnectivityAndFetch();
  }

  // Load authentication token from secure storage
  Future<void> _loadToken() async {
    final token = await SharedPrefHelper.getToken();
    if (mounted) {
      setState(() => _token = token ?? '');
    }
  }

  // Check network before fetching data
  Future<void> _checkConnectivityAndFetch() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          _error = 'No internet connection';
          _isLoading = false;
        });
      }
      _showErrorSnackbar('Please check your internet connection');
      return;
    }
    await _fetchDayLogs();
  }

  // Fetch logs from API
  Future<void> _fetchDayLogs() async {
    setState(() => _isLoading = true);

    try {
      final response = await _service.getDayLogs(_token!);
      final logs = response?.data?.data ?? [];

      setState(() {
        _allLogs = logs;
        _filteredLogs = List.from(logs);
      });
    } catch (e) {
      if (e is UnauthorizedException) {
        setState(() {
          _isLoading = false;
        });
        SharedPrefHelper.clearUser();
        _redirectToLogin();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Filter logs based on search query
  void _filterLogs() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredLogs =
          _allLogs.where((log) {
            final placeMatch =
                log.placeVisit?.toLowerCase().contains(query) ?? false;
            final purposeMatch =
                log.tourPurpose?.name?.toLowerCase().contains(query) ?? false;
            return placeMatch || purposeMatch;
          }).toList();
    });
  }

  // Show error message
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Navigation Methods
  void _navigateToAddLog() {
    Navigator.pushNamed(context, '/addDayLog').then((_) => _fetchDayLogs());
  }

  Future<void> _navigateToTracking(DayLogsDataModel log) async {
    // Show loading indicator during navigation transition
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => LiveMapScreen(logId: log.id!),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // Remove loading indicator
    if (mounted) Navigator.of(context).pop();

    // Refresh if tracking was completed
    if (result == true && mounted) {
      await _fetchDayLogs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day Logs')),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLog,
        tooltip: 'Add new log',
        child: Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Field
              _buildSearchField(),
              const SizedBox(height: 16),

              // Main Content
              Expanded(child: _buildBodyContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search logs...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon:
            _isSearching
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _isSearching = false);
                  },
                )
                : null,
      ),
    );
  }

  Widget _buildBodyContent() {
    // Show loading shimmer on initial load
    if (_isLoading && _filteredLogs.isEmpty) {
      return _buildLoadingShimmer();
    }

    // Show error state if something went wrong
    if (_error != null && _filteredLogs.isEmpty) {
      return _buildErrorState();
    }

    // Show empty state if no logs found
    if (_filteredLogs.isEmpty) {
      return _buildEmptyState();
    }

    // Main list with refresh
    return RefreshIndicator(
      onRefresh: _fetchDayLogs,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _filteredLogs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildLogCard(_filteredLogs[index]),
      ),
    );
  }

  Widget _buildLogCard(DayLogsDataModel log) {
    final theme = Theme.of(context);
    final hasClosingKm = log.closingKm != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTracking(log),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and status
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy hh:mm a',
                    ).format(DateTime.parse(log.createdAt!)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (hasClosingKm)
                    Chip(
                      label: const Text('Completed'),
                      backgroundColor: Colors.green[50],
                      labelStyle: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Log details
              _buildInfoRow(
                Icons.place,
                log.placeVisit ?? 'No location specified',
              ),
              _buildInfoRow(
                Icons.work,
                log.tourPurpose?.name ?? 'No purpose specified',
              ),

              // Tracking button for incomplete logs
              if (!hasClosingKm) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions_walk, size: 20),
                    label: const Text('Start Tracking'),
                    onPressed: () => _navigateToTracking(log),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder:
          (_, index) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
            ),
          ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load logs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error occurred', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _checkConnectivityAndFetch,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No matching logs found' : 'No logs available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
