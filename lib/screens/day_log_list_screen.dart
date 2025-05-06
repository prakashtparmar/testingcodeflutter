import 'package:flutter/material.dart';
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

class DayLogsListScreen extends StatefulWidget {
  const DayLogsListScreen({super.key});

  @override
  State<DayLogsListScreen> createState() => _DayLogsListScreenState();
}

class _DayLogsListScreenState extends State<DayLogsListScreen> {
  String? _token;
  final BasicService _service = BasicService();
  List<DayLogsDataModel> dayLogs = [];
  List<DayLogsDataModel> filteredLogs = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLogs);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _fetchDayLogs();
  }

  Future<void> _loadUser() async {
    final tokenData = await SharedPrefHelper.getToken();
    debugPrint(tokenData);
    setState(() {
      _token = tokenData ?? "";
    });
  }

  Future<void> _fetchDayLogs() async {
    try {
      final response = await _service.getDayLogs(_token!);

      setState(() {
        if (response != null && response.data != null) {
          dayLogs = response.data!.data!;
          filteredLogs = List.from(dayLogs);
        } else {
          _errorMessage = "No logs found.";
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading logs: $e";
        isLoading = false;
      });
    }
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredLogs =
          dayLogs
              .where((log) => log.placeVisit!.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigationRoutes(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
        _errorMessage = null;
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Day Logs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Logs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : Expanded(
                    child: ListView.separated(
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              _buildLogTile(filteredLogs[index]),
                    ),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigationRoutes(context, "/addDayLog");
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLogTile(DayLogsDataModel log) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const Icon(
          Icons.calendar_today_outlined,
          color: Colors.blueAccent,
        ),
        title: Text(
          log.placeVisit!,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped: $log')));
        },
      ),
    );
  }
}
