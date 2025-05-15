import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ap/pastel_theme.dart';

class GenerateReportsPage extends StatefulWidget {
  const GenerateReportsPage({super.key});

  @override
  GenerateReportsPageState createState() => GenerateReportsPageState();
}

class GenerateReportsPageState extends State<GenerateReportsPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _reportType = 'Sales';
  bool _isGenerating = false;
  bool _reportGenerated = false;
  bool _dataFetched = false;
  
  final List<String> _reportTypes = ['Sales', 'Inventory', 'Orders', 'Products'];
  List<Map<String, dynamic>> _reportData = [];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PastelTheme.primary,
              onPrimary: Colors.white,
              surface: PastelTheme.background,
              onSurface: PastelTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isGenerating = true;
      _dataFetched = false;
    });

    try {
      final collection = FirebaseFirestore.instance.collection(_reportType);
      QuerySnapshot snapshot = await collection
          .where('date', isGreaterThanOrEqualTo: _startDate)
          .where('date', isLessThanOrEqualTo: _endDate)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _reportData = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          _dataFetched = true;
        });
      } else {
        setState(() {
          _dataFetched = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data found for the selected range.'),
            backgroundColor: PastelTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _dataFetched = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: PastelTheme.error,
        ),
      );
    }

    setState(() {
      _isGenerating = false;
      _reportGenerated = true;
    });
  }

  Widget _buildReportContent() {
    if (_reportType == 'Sales') {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(top: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Sales Report',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: PastelTheme.textPrimary,
                  ),
                ),
              ),
              const Divider(color: PastelTheme.divider),
              Row(
                children: [
                  Text(
                    'Date Range: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PastelTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    style: TextStyle(
                      color: PastelTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSalesTable(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'PDF',
                    color: PastelTheme.success,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report downloaded successfully'),
                          backgroundColor: PastelTheme.success,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.email,
                    label: 'Email',
                    color: PastelTheme.primary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report sent by email'),
                          backgroundColor: PastelTheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(top: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              '$_reportType report generation is not implemented yet.',
              style: TextStyle(
                fontSize: 14,
                color: PastelTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(90, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSalesTable() {
    if (!_dataFetched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
          ),
        ),
      );
    }

    if (_reportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No data available for the selected period',
            style: TextStyle(
              color: PastelTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PastelTheme.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => PastelTheme.background,
          ),
          dataRowMaxHeight: 48,
          headingRowHeight: 40,
          columns: [
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PastelTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Amount (USD)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PastelTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Orders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PastelTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          rows: _reportData.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    item['date'].toString(),
                    style: TextStyle(
                      color: PastelTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '\$${item['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: PastelTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${item['orders']}',
                    style: TextStyle(
                      color: PastelTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: PastelTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Parameters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const Divider(color: PastelTheme.divider),
                      const SizedBox(height: 12),
                      
                      // Date Range Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateSelector(
                              label: 'Start Date',
                              isStart: true,
                              date: _startDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateSelector(
                              label: 'End Date',
                              isStart: false,
                              date: _endDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Report Type
                      Text(
                        'Report Type:',
                        style: TextStyle(
                          fontSize: 13,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: PastelTheme.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _reportType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: _reportTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: PastelTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _reportType = value!;
                            });
                          },
                          dropdownColor: Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: PastelTheme.textPrimary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _fetchReportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(180, 44),
                          ),
                          child: _isGenerating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Generate Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_reportGenerated) _buildReportContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required bool isStart,
    required DateTime date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: PastelTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: PastelTheme.inputBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    color: PastelTheme.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: PastelTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}