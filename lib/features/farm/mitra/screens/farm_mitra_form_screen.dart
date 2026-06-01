import 'package:flutter/material.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../models/mitra_model.dart';

class FarmMitraFormScreen extends StatefulWidget {
  final MitraPartnership? mitra;

  const FarmMitraFormScreen({super.key, this.mitra});

  @override
  State<FarmMitraFormScreen> createState() => _FarmMitraFormScreenState();
}

class _FarmMitraFormScreenState extends State<FarmMitraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _categoryController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;
  String _selectedIcon = 'business';
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'business', 'icon': Icons.business_rounded},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart_rounded},
    {'name': 'local_shipping', 'icon': Icons.local_shipping_rounded},
    {'name': 'factory', 'icon': Icons.factory_rounded},
    {'name': 'handshake', 'icon': Icons.handshake_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.mitra?.mitraName ?? '',
    );
    _companyController = TextEditingController(
      text: widget.mitra?.companyName ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.mitra?.category ?? '',
    );
    _contactController = TextEditingController(
      text: widget.mitra?.contact ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.mitra?.description ?? '',
    );
    _selectedIcon = widget.mitra?.logoIcon ?? 'business';
    _isActive = widget.mitra?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dao = DatabaseHelper.instance.mitraDao;
      final mitraData = MitraPartnership(
        id: widget.mitra?.id,
        mitraName: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        category: _categoryController.text.trim(),
        contact: _contactController.text.trim(),
        joinedDate:
            widget.mitra?.joinedDate ??
            DateTime.now().toIso8601String().substring(0, 10),
        isActive: _isActive,
        description: _descriptionController.text.trim(),
        logoIcon: _selectedIcon,
      );

      if (widget.mitra == null) {
        await dao.insert(mitraData);
      } else {
        await dao.update(mitraData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mitra == null ? 'Tambah Mitra Baru' : 'Edit Mitra',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Singkat Mitra',
                      hint: 'Contoh: KomarExpress',
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _companyController,
                      label: 'Nama Perusahaan Lengkap',
                      hint: 'Contoh: PT Komar Express Nusantara',
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _categoryController,
                      label: 'Kategori Bisnis',
                      hint: 'Contoh: Restoran, Distributor, Pabrik',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactController,
                      label: 'Kontak / Email',
                      hint: 'Contoh: 0812xxx atau email@mitra.com',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Deskripsi Kerjasama',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ikon Representatif',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: _iconOptions.map((opt) {
                        final selected = _selectedIcon == opt['name'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIcon = opt['name']),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryGreen
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Icon(
                              opt['icon'],
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      subtitle: const Text(
                        'Mitra akan muncul di pilihan penjualan panen',
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text(
                          'Simpan Data Mitra',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
