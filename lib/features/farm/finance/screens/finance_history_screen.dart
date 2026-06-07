import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komars_express/core/routes/app_routes.dart';
import '../models/financial_record_model.dart';
import '../widgets/profit_loss_card.dart';
import 'finance_input_screen.dart';
import 'finance_detail_screen.dart';

class FinanceHistoryScreen extends StatefulWidget {
  final int userId;
  final bool embedded;

  const FinanceHistoryScreen({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  @override
  State<FinanceHistoryScreen> createState() => _FinanceHistoryScreenState();
}

class _FinanceHistoryScreenState extends State<FinanceHistoryScreen> {
  late DatabaseHelper _dbHelper;
  late SharedPreferences _prefs;

  String _selectedFarmType = 'unggas';
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
    _selectedFarmType = _prefs.getString(PrefKeys.selectedFarmType) ?? 'unggas';
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

      // Hitung total semua catatan
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
        title: const Text('Hapus Catatan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan tanggal ${DateFormat('dd MMM yyyy').format(DateTime.parse(record.recordDate))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecord(record.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.expressCustomerHome);
                  }
                },
                tooltip: 'Kembali ke Komars Express',
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Keuangan Tani',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : Colors.transparent,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jenis Tani',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _selectedFarmType.toLowerCase(),
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['unggas', 'ikan', 'sayur']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      type[0].toUpperCase() +
                                          type.substring(1),
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
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
                    const SizedBox(height: 24),

                    // Financial Summary Card
                    ProfitLossCard(
                      income: _totalIncome,
                      expense: _totalExpense,
                      loss: _totalLoss,
                      netProfit: _totalProfit,
                      title: 'Ringkasan Keuangan',
                    ),
                    const SizedBox(height: 24),

                    // Records List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Catatan',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    FinanceInputScreen(userId: widget.userId),
                              ),
                            );
                            if (success == true) _loadRecords();
                          },
                          child: const Text('Tambah Baru'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _records.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada catatan keuangan\nuntuk kategori ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.grey.shade500,
                                    ),
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

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkDivider : Colors.grey.shade100,
                                  ),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) =>
                                            FinanceDetailScreen(record: record),
                                      ),
                                    );
                                    _loadRecords();
                                  },
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isProfit
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isProfit
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      color: isProfit
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(DateTime.parse(record.recordDate)),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    (record.notes == null ||
                                            record.notes!.isEmpty)
                                        ? 'Tidak ada catatan'
                                        : record.notes!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rp ${record.income.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '${isProfit ? '+' : ''}Rp ${record.netProfit.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontWeight: FontWeight.w900,
                                              color: isProfit
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _showDeleteConfirmation(record),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        tooltip: 'Hapus catatan',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => FinanceInputScreen(userId: widget.userId),
            ),
          );
          if (success == true) _loadRecords();
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
