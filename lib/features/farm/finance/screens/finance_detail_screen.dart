import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../models/financial_record_model.dart';

class FinanceDetailScreen extends StatefulWidget {
  final FinancialRecord record;

  const FinanceDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  State<FinanceDetailScreen> createState() => _FinanceDetailScreenState();
}

class _FinanceDetailScreenState extends State<FinanceDetailScreen> {
  late DatabaseHelper _dbHelper;
  late TextEditingController _incomeController;
  late TextEditingController _expenseController;
  late TextEditingController _lossController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper.instance;
    _selectedDate = DateTime.parse(widget.record.recordDate);
    _incomeController = TextEditingController(
      text: widget.record.income.toString(),
    );
    _expenseController = TextEditingController(
      text: widget.record.expense.toString(),
    );
    _lossController = TextEditingController(
      text: widget.record.loss.toString(),
    );
    _notesController = TextEditingController(text: widget.record.notes ?? '');
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _lossController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateRecord() async {
    if (_incomeController.text.isEmpty ||
        _expenseController.text.isEmpty ||
        _lossController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final income = double.parse(_incomeController.text);
      final expense = double.parse(_expenseController.text);
      final loss = double.parse(_lossController.text);
      final netProfit = income - expense - loss;

      final updatedRecord = widget.record.copyWith(
        income: income,
        expense: expense,
        loss: loss,
        netProfit: netProfit,
        recordDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        notes: _notesController.text,
        updatedAt: DateTime.now().toString(),
      );

      final dao = _dbHelper.financialRecordDao;
      await dao.updateRecord(updatedRecord);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.record.netProfit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Record Detail'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Farm Type Header
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Date',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Date',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMMM yyyy').format(
                                    DateTime.parse(widget.record.recordDate),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Farm Type: ${widget.record.farmType}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Financial Details
                  if (_isEditing) ...[
                    Text(
                      'Income *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _incomeController,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Expense *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _expenseController,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loss *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lossController,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notes (Optional)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ] else ...[
                    _DetailCard(
                      label: 'Income',
                      amount: widget.record.income,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      label: 'Expense',
                      amount: widget.record.expense,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      label: 'Loss',
                      amount: widget.record.loss,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    _DetailCard(
                      label: 'Net Profit',
                      amount: widget.record.netProfit,
                      color: profitColor,
                      isHighlight: true,
                    ),
                    if (widget.record.notes != null &&
                        widget.record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          widget.record.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateRecord,
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isHighlight;

  const _DetailCard({
    Key? key,
    required this.label,
    required this.amount,
    required this.color,
    this.isHighlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: isHighlight ? 2 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            amount >= 0 ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 32,
          ),
        ],
      ),
    );
  }
}

