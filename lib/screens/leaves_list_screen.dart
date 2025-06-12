import 'package:flutter/material.dart';
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/models/leaves_data_model.dart';
import 'package:snap_check/screens/live_map_screen.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

class LeavesListScreen extends StatefulWidget {
  const LeavesListScreen({super.key});

  @override
  State<LeavesListScreen> createState() => _LeavesListScreenState();
}

class _LeavesListScreenState extends State<LeavesListScreen> {
  final BasicService _service = BasicService();
  final TextEditingController _searchController = TextEditingController();

  List<LeavesDataModel> _allLogs = [];
  List<LeavesDataModel> _filteredLogs = [];

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
    await _fetchDayLogs();
  }

  Future<void> _loadToken() async {
    final token = await SharedPrefHelper.getToken();
    setState(() {
      _token = token ?? '';
    });
  }

  Future<void> _fetchDayLogs() async {
    setState(() => _isLoading = true);

    try {
      final response = await _service.getLeaves(_token!);
      final logs = response?.data ?? [];

      setState(() {
        _allLogs = logs;
        _filteredLogs = List.from(logs);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterLogs() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLogs =
          _allLogs
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
    Navigator.pushNamed(context, '/addDayLog');
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
                          onRefresh: _fetchDayLogs,
                          child:
                              _filteredLogs.isEmpty
                                  ? const Center(
                                    child: Text('No matching logs found.'),
                                  )
                                  : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _filteredLogs.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 12),
                                    itemBuilder:
                                        (_, index) =>
                                            _buildLogCard(_filteredLogs[index]),
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
        labelText: 'Search Logs',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLogCard(LeavesDataModel log) {
    final hasClosingKm = log.approvedBy != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: hasClosingKm ? null : 140, // adjust height if needed
          child: Column(
            mainAxisAlignment:
                hasClosingKm
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRowWithIcon(
                Icons.work_outline,
                log.leaveType?.name ?? 'No purpose',
              ),
              const SizedBox(height: 8),
              _buildRowWithIcon(
                Icons.place,
                log.reason ?? 'No place',
                iconSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowWithIcon(IconData icon, String text, {double iconSize = 20}) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
