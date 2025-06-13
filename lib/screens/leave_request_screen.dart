import 'package:flutter/material.dart';
import 'package:snap_check/models/leave_type_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final BasicService _basicService = BasicService();
  final DateFormat apiFormat = DateFormat('yyyy/MM/dd');
  final DateFormat displayFormat = DateFormat('d MMMM yyyy');

  // Dropdown items
  List<LeaveTypeModel> leaveTypes = [];
  String? _token;

  LeaveTypeModel? selectedLeaveType;
  String? reason;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final tokenData = await SharedPrefHelper.getToken();

    setState(() {
      _token = tokenData ?? "";
    });
    _fetchLeaveTypes();
  }

  Future<void> _fetchLeaveTypes() async {
    try {
      setState(() => _isLoading = true);

      final response = await _basicService.getLeaveTypes(_token!);
      if (response != null && response.data != null) {
        setState(() {
          leaveTypes = response.data!;
          selectedLeaveType = response.data!.first;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tour details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                    key: _formKey,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Leave Details",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            _buildDropdownField(
                              'Leave Type',
                              leaveTypes,
                              selectedLeaveType,
                              (val) {
                                setState(() {
                                  selectedLeaveType = val;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              onChanged: (val) => reason = val,
                              validator:
                                  (val) =>
                                      val == null || val.isEmpty
                                          ? 'Enter reason'
                                          : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Date',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _startDate != null
                                            ? displayFormat.format(_startDate!)
                                            : 'Select start date',
                                        style: TextStyle(
                                          color:
                                              _startDate != null
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap:
                                        _startDate == null
                                            ? null
                                            : () => _selectDate(context, false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'End Date',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _endDate != null
                                            ? displayFormat.format(_endDate!)
                                            : 'Select end date',
                                        style: TextStyle(
                                          color:
                                              _endDate != null
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Submit Leave Request'),
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<LeaveTypeModel> items,
    LeaveTypeModel? selected,
    ValueChanged<LeaveTypeModel?> onChanged,
  ) {
    return DropdownButtonFormField<LeaveTypeModel>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: selected,
      items:
          items
              .map(
                (e) => DropdownMenuItem<LeaveTypeModel>(
                  value: e, // or e.id, based on your logic
                  child: Text(e.name!),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart
            ? (_startDate ?? DateTime.now())
            : (_endDate ?? _startDate ?? DateTime.now());
    final firstDate = isStart ? DateTime.now() : _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _endDate = null; // reset end date
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and attach image.'),
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }
    // Base form data
    final Map<String, String> formData = {
      "leave_type_id": selectedLeaveType!.id.toString(),
      "start_date": apiFormat.format(_startDate!),
      "end_date": apiFormat.format(_endDate!),
      "reason": reason!,
    };

    // PostDayLogsResponseModel? postDayLogsResponseModel = await _basicService
    //     .postDayLog(_token!, imageFile, formData);
    // if (postDayLogsResponseModel != null &&
    //     postDayLogsResponseModel.success == true) {
    //   if (!mounted) {
    //     return;
    //   }
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(postDayLogsResponseModel.message!)),
    //   );
    //   Navigator.pop(context);
    // } else if (postDayLogsResponseModel != null &&
    //     postDayLogsResponseModel.success == false) {
    //   if (!mounted) {
    //     return;
    //   }
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(postDayLogsResponseModel.message!)),
    //   );
    // }
  }
}
