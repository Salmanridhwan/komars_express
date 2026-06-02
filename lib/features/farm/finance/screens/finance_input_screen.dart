import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:komars_express/core/constants/app_colors.dart';
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

  String _selectedFarmType = 'unggas';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _dbHelper = DatabaseHelper.instance;
    _prefs = await SharedPreferences.getInstance();
    _selectedFarmType = _prefs.getString(PrefKeys.selectedFarmType) ?? 'unggas';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_chart_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tambah Catatan',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Type Card (Read Only or Indicator)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jenis Tani',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _selectedFarmType[0].toUpperCase() +
                            _selectedFarmType.substring(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Selector
            const Text(
              'Tanggal Catatan',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontFamily: 'Outfit'),
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Income Input
            _buildInputField(
              label: 'Pemasukan (Income) *',
              controller: _incomeController,
              hint: '0',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.statusSuccess,
            ),
            const SizedBox(height: 16),

            // Expense Input
            _buildInputField(
              label: 'Pengeluaran (Expense) *',
              controller: _expenseController,
              hint: '0',
              icon: Icons.remove_circle_outline_rounded,
              color: AppColors.secondaryOrange,
            ),
            const SizedBox(height: 16),

            // Loss Input
            _buildInputField(
              label: 'Kerugian/Kematian (Loss) *',
              controller: _lossController,
              hint: '0',
              icon: Icons.error_outline_rounded,
              color: AppColors.statusCancelled,
            ),
            const SizedBox(height: 24),

            // Notes Input
            const Text(
              'Catatan Tambahan',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Misal: Penjualan panen tomat atau biaya pakan...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Catatan',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : Colors.black87,
            ),
            suffixIcon: Icon(icon, color: color.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
