import 'package:flutter/material.dart';
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/screens/live_map_screen.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

class DayLogsListScreen extends StatefulWidget {
  const DayLogsListScreen({super.key});

  @override
  State<DayLogsListScreen> createState() => _DayLogsListScreenState();
}

class _DayLogsListScreenState extends State<DayLogsListScreen> {
  final BasicService _service = BasicService();
  final TextEditingController _searchController = TextEditingController();

  List<DayLogsDataModel> _allLogs = [];
  List<DayLogsDataModel> _filteredLogs = [];

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
      final response = await _service.getDayLogs(_token!);
      final logs = response?.data?.data ?? [];

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
                (log) => log.placeVisit?.toLowerCase().contains(query) ?? false,
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

  void _navigateToTracking(DayLogsDataModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveMapScreen(logId: log.id!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day Logs')),
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

  Widget _buildLogCard(DayLogsDataModel log) {
    final hasClosingKm = log.closingKm != null;

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
                log.tourPurpose?.name ?? 'No purpose',
              ),
              const SizedBox(height: 8),
              _buildRowWithIcon(
                Icons.place,
                log.placeVisit ?? 'No place',
                iconSize: 16,
              ),
              if (!hasClosingKm) ...[
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToTracking(log),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
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
