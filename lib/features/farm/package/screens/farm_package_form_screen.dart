import 'package:flutter/material.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import '../models/farm_package_model.dart';

class FarmPackageFormScreen extends StatefulWidget {
  final FarmPackage? package;

  const FarmPackageFormScreen({super.key, this.package});

  @override
  State<FarmPackageFormScreen> createState() => _FarmPackageFormScreenState();
}

class _FarmPackageFormScreenState extends State<FarmPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseHelper _dbHelper;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _farmTypeController;
  late TextEditingController _minCapitalController;
  late TextEditingController _recCapitalController;
  late TextEditingController _harvestDaysController;
  late TextEditingController _roiMonthsController;
  late TextEditingController _monthlyIncomeController;
  late TextEditingController _equipmentListController;
  late TextEditingController _stepsController;

  // Preset farm types — harus sinkron dengan _farmTypeLabels di farm_harvest_sale_screen
  final List<String> _presetFarmTypes = ['unggas', 'ikan', 'sayur', 'campuran'];

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper.instance;

    // Initialize controllers with existing data or defaults
    _titleController = TextEditingController(text: widget.package?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.package?.description ?? '',
    );
    _farmTypeController = TextEditingController(
      text: widget.package?.farmType ?? 'unggas',
    );
    _minCapitalController = TextEditingController(
      text: widget.package != null
          ? widget.package!.initialCapitalMin.toStringAsFixed(0)
          : '',
    );
    _recCapitalController = TextEditingController(
      text: widget.package != null
          ? widget.package!.initialCapitalRec.toStringAsFixed(0)
          : '',
    );
    _harvestDaysController = TextEditingController(
      text: widget.package != null
          ? widget.package!.harvestTimeDays.toString()
          : '',
    );
    _roiMonthsController = TextEditingController(
      text: widget.package != null ? widget.package!.roiMonths.toString() : '',
    );
    _monthlyIncomeController = TextEditingController(
      text: widget.package != null
          ? widget.package!.monthlyIncomeEst.toStringAsFixed(0)
          : '',
    );
    _equipmentListController = TextEditingController(
      text: widget.package?.equipmentList.join('\n') ?? '',
    );
    _stepsController = TextEditingController(
      text: widget.package?.steps.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _farmTypeController.dispose();
    _minCapitalController.dispose();
    _recCapitalController.dispose();
    _harvestDaysController.dispose();
    _roiMonthsController.dispose();
    _monthlyIncomeController.dispose();
    _equipmentListController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final equipment = _equipmentListController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      final steps = _stepsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      final newPackage = FarmPackage(
        id: widget.package?.id ?? 0,
        farmType: _farmTypeController.text.trim().toLowerCase(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        initialCapitalMin: double.parse(_minCapitalController.text),
        initialCapitalRec: double.parse(_recCapitalController.text),
        harvestTimeDays: int.parse(_harvestDaysController.text),
        roiMonths: int.parse(_roiMonthsController.text),
        monthlyIncomeEst: double.parse(_monthlyIncomeController.text),
        steps: steps,
        equipmentList: equipment,
      );

      final dao = _dbHelper.farmPackageDao;
      if (widget.package == null) {
        await dao.insertPackage(newPackage);
      } else {
        await dao.updatePackage(newPackage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.package == null
                  ? 'Paket investasi berhasil ditambahkan'
                  : 'Paket investasi berhasil diperbarui',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan paket: $e',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    int maxLines = 1,
    bool isNumber = false,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$labelText wajib diisi';
              }
              if (isNumber) {
                final parsedValue = double.tryParse(value);
                if (parsedValue == null || parsedValue < 0) {
                  return 'Masukkan nilai angka yang valid';
                }
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            fontFamily: 'Outfit',
            color: Colors.grey[600],
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.primaryGreen,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.primaryGreen, size: 22),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.statusCancelled, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.statusCancelled, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.package != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Paket Investasi' : 'Tambah Paket Investasi',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Informasi Dasar'),
              _buildTextFormField(
                controller: _titleController,
                labelText: 'Nama Paket Investasi',
                prefixIcon: Icons.title_rounded,
              ),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Deskripsi Paket',
                prefixIcon: Icons.description_rounded,
                maxLines: 3,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Kategori Usaha Tani',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: _presetFarmTypes.length,
                  itemBuilder: (context, i) {
                    final type = _presetFarmTypes[i];
                    final isSelected =
                        _farmTypeController.text.trim().toLowerCase() == type;

                    String label;
                    Color color;

                    switch (type) {
                      case 'unggas':
                        label = '🐔 Unggas';
                        color = Colors.orange;
                        break;
                      case 'ikan':
                        label = '🐟 Ikan';
                        color = Colors.blue;
                        break;
                      case 'sayur':
                        label = '🥬 Sayur';
                        color = Colors.green;
                        break;
                      default:
                        label = '🌾 Campuran';
                        color = Colors.brown;
                    }

                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _farmTypeController.text = type;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : (isDark ? AppColors.darkDivider : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isSelected ? color : (isDark ? Colors.white70 : Colors.grey.shade700),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              _buildSectionHeader('Aspek Finansial'),
              _buildTextFormField(
                controller: _minCapitalController,
                labelText: 'Modal Awal Minimum',
                prefixIcon: Icons.payments_rounded,
                isNumber: true,
                suffixText: 'IDR',
              ),
              _buildTextFormField(
                controller: _recCapitalController,
                labelText: 'Modal Awal Direkomendasikan',
                prefixIcon: Icons.account_balance_wallet_rounded,
                isNumber: true,
                suffixText: 'IDR',
              ),
              _buildTextFormField(
                controller: _monthlyIncomeController,
                labelText: 'Estimasi Pendapatan Bulanan',
                prefixIcon: Icons.monetization_on_rounded,
                isNumber: true,
                suffixText: 'IDR',
              ),

              _buildSectionHeader('Jangka Waktu & Imbal Hasil'),
              _buildTextFormField(
                controller: _harvestDaysController,
                labelText: 'Lama Waktu Panen',
                prefixIcon: Icons.calendar_today_rounded,
                isNumber: true,
                suffixText: 'Hari',
              ),
              _buildTextFormField(
                controller: _roiMonthsController,
                labelText: 'Mulai Menghasilkan ROI',
                prefixIcon: Icons.trending_up_rounded,
                isNumber: true,
                suffixText: 'Bulan',
              ),

              _buildSectionHeader('Panduan & Persiapan'),
              _buildTextFormField(
                controller: _equipmentListController,
                labelText: 'Alat & Bahan (Gunakan baris baru)',
                prefixIcon: Icons.shopping_basket_rounded,
                maxLines: 5,
              ),
              _buildTextFormField(
                controller: _stepsController,
                labelText: 'Langkah-langkah (Gunakan baris baru)',
                prefixIcon: Icons.list_alt_rounded,
                maxLines: 8,
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePackage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Simpan Perubahan' : 'Tambah Paket',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
