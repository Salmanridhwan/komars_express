import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/financial_record_model.dart';
import '../widgets/profit_loss_card.dart';
import 'finance_input_screen.dart';
import 'finance_detail_screen.dart';

class FinanceHistoryScreen extends StatefulWidget {
  final int userId;

  const FinanceHistoryScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<FinanceHistoryScreen> createState() => _FinanceHistoryScreenState();
}

class _FinanceHistoryScreenState extends State<FinanceHistoryScreen> {
  late DatabaseHelper _dbHelper;
  late SharedPreferences _prefs;

  String _selectedFarmType = 'ayam';
  String _filterPeriod = 'weekly';
  List<FinancialRecord> _records = [];
  bool _isLoading = true;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalLoss = 0;
  double _totalProfit = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _dbHelper = DatabaseHelper.instance;
    _prefs = await SharedPreferences.getInstance();
    _selectedFarmType = _prefs.getString(PrefKeys.selectedFarmType) ?? 'ayam';
    _filterPeriod = _prefs.getString(PrefKeys.financeFilterPeriod) ?? 'weekly';
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final dao = _dbHelper.financialRecordDao;
      final records = await dao.getRecordsByUserAndFarmType(
        widget.userId,
        _selectedFarmType,
      );

      // Calculate totals
      _totalIncome = records.fold(0, (sum, r) => sum + r.income);
      _totalExpense = records.fold(0, (sum, r) => sum + r.expense);
      _totalLoss = records.fold(0, (sum, r) => sum + r.loss);
      _totalProfit = records.fold(0, (sum, r) => sum + r.netProfit);

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading records: $e')));
      }
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      final dao = _dbHelper.financialRecordDao;
      await dao.deleteRecord(id);
      await _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmation(FinancialRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete the record from ${DateFormat('dd MMM yyyy').format(DateTime.parse(record.recordDate))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecord(record.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance History'), elevation: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FinanceInputScreen(userId: widget.userId),
            ),
          ).then((result) {
            if (result == true) {
              _loadRecords();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Type and Filter Controls
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farm Type',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: _selectedFarmType,
                              isExpanded: true,
                              items: ['ayam', 'lele', 'hidroponik', 'sayuran']
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedFarmType = value);
                                  _prefs.setString(
                                    PrefKeys.selectedFarmType,
                                    value,
                                  );
                                  _loadRecords();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Period',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: _filterPeriod,
                              isExpanded: true,
                              items: ['weekly', 'monthly']
                                  .map(
                                    (period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(period),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _filterPeriod = value);
                                  _prefs.setString(
                                    PrefKeys.financeFilterPeriod,
                                    value,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Financial Summary Card
                  ProfitLossCard(
                    income: _totalIncome,
                    expense: _totalExpense,
                    loss: _totalLoss,
                    netProfit: _totalProfit,
                    title: 'Total Summary',
                  ),
                  const SizedBox(height: 24),

                  // Records List
                  Text(
                    'Records',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            final isProfit = record.netProfit >= 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isProfit
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isProfit
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: isProfit ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(record.recordDate)),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Income: Rp ${record.income.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Profit: Rp ${record.netProfit.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isProfit
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FinanceDetailScreen(
                                                    record: record,
                                                  ),
                                            ),
                                          ).then((result) {
                                            if (result == true) {
                                              _loadRecords();
                                            }
                                          });
                                        });
                                      },
                                      child: const Text('View'),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          _showDeleteConfirmation(record);
                                        });
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

