import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/financial_record_model.dart';

class FinanceInputScreen extends StatefulWidget {
  final int userId;

  const FinanceInputScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<FinanceInputScreen> createState() => _FinanceInputScreenState();
}

class _FinanceInputScreenState extends State<FinanceInputScreen> {
  late DatabaseHelper _dbHelper;
  late SharedPreferences _prefs;

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _lossController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedFarmType = 'ayam';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _dbHelper = DatabaseHelper.instance;
    _prefs = await SharedPreferences.getInstance();
    _selectedFarmType = _prefs.getString(PrefKeys.selectedFarmType) ?? 'ayam';
    setState(() {});
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

  Future<void> _submitForm() async {
    if (_incomeController.text.isEmpty ||
        _expenseController.text.isEmpty ||
        _lossController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final income = double.parse(_incomeController.text);
      final expense = double.parse(_expenseController.text);
      final loss = double.parse(_lossController.text);
      final netProfit = income - expense - loss;

      final record = FinancialRecord(
        id: 0,
        userId: widget.userId,
        farmType: _selectedFarmType,
        recordDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        income: income,
        expense: expense,
        loss: loss,
        netProfit: netProfit,
        notes: _notesController.text,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );

      final dao = _dbHelper.financialRecordDao;
      await dao.insertRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _lossController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Financial Record'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Type Selector
            Text(
              'Farm Type',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedFarmType,
              isExpanded: true,
              items: ['ayam', 'lele', 'hidroponik', 'sayuran']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFarmType = value);
                  _prefs.setString(PrefKeys.selectedFarmType, value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Date Selector
            Text(
              'Record Date',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Income Input
            Text(
              'Income *',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeController,
              decoration: InputDecoration(
                hintText: 'Enter income amount',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Expense Input
            Text(
              'Expense *',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _expenseController,
              decoration: InputDecoration(
                hintText: 'Enter expense amount',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Loss Input
            Text(
              'Loss *',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lossController,
              decoration: InputDecoration(
                hintText: 'Enter loss amount',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Notes Input
            Text(
              'Notes (Optional)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

