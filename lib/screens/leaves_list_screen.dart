import 'package:flutter/material.dart';
import 'package:snap_check/models/leaves_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:readmore/readmore.dart';
import 'package:snap_check/theme/theme_provider.dart';

class LeavesListScreen extends StatefulWidget {
  const LeavesListScreen({super.key});

  @override
  State<LeavesListScreen> createState() => _LeavesListScreenState();
}

class _LeavesListScreenState extends State<LeavesListScreen> {
  final BasicService _service = BasicService();
  final TextEditingController _searchController = TextEditingController();

  List<LeavesDataModel> _allLeaves = [];
  List<LeavesDataModel> _filteredLeaves = [];

  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLogs);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadToken();
    await _fetchMyLeaves();
  }

  Future<void> _loadToken() async {
    final token = await SharedPrefHelper.getToken();
    setState(() {
      _token = token ?? '';
    });
  }

  Future<void> _fetchMyLeaves() async {
    setState(() => _isLoading = true);

    try {
      final response = await _service.getLeaves(_token!);
      final logs = response?.data ?? [];

      setState(() {
        _allLeaves = logs;
        _filteredLeaves = List.from(logs);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterLogs() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLeaves =
          _allLeaves
              .where(
                (log) => log.reason?.toLowerCase().contains(query) ?? false,
              )
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddLog() {
    Navigator.pushNamed(context, '/leaveRequest');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaves')),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _fetchMyLeaves,
                          child:
                              _filteredLeaves.isEmpty
                                  ? const Center(
                                    child: Text('No matching logs found.'),
                                  )
                                  : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _filteredLeaves.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 12),
                                    itemBuilder:
                                        (_, index) => _buildLogCard(
                                          _filteredLeaves[index],
                                        ),
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search Leaves',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLogCard(LeavesDataModel log) {
    final status = (log.status ?? 'pending').toLowerCase();
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    final leaveDate = log.startDate ?? 'Unknown';
    final leaveType = log.leaveType?.name ?? 'Leave';
    final duration = _getDurationText(log.startDate, log.endDate);
    final reason = log.reason ?? 'No reason provided';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Date (Left) and Status (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(leaveDate),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(
                      38,
                    ), // Equivalent to 15% opacity

                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Reason
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ReadMoreText(
                reason.trim(),
                trimLines: 2,
                trimMode: TrimMode.Line,
                trimCollapsedText: ' Read more',
                trimExpandedText: ' Read less',
                moreStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
                lessStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$duration, $leaveType",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    // Parse & format date (assuming yyyy-MM-dd)
    try {
      final parsed = DateTime.parse(date);
      return "${_monthName(parsed.month)} ${parsed.day}";
    } catch (_) {
      return date;
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _getDurationText(String? start, String? end) {
    if (start == null || end == null) return '';
    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      final days = endDate.difference(startDate).inDays + 1;
      return "$days Day${days > 1 ? 's' : ''}";
    } catch (_) {
      return '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}
