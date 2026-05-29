import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../db/menu_dao.dart';
import '../models/menu_item_model.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _menuDao = MenuDao();
  List<MenuItemModel> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMenus();
  }

  Future<void> _loadAllMenus() async {
    setState(() => _isLoading = true);
    final items = await _menuDao.getAll();
    if (mounted) {
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMenu(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu?'),
        content: Text('Apakah Anda yakin ingin menghapus "${item.name}" dari daftar menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await _menuDao.delete(item.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.name}" berhasil dihapus')),
      );
      _loadAllMenus();
    }
  }

  void _openFormModal({MenuItemModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuFormBottomSheet(
        item: item,
        onSave: () {
          _loadAllMenus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu (Kasir/Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllMenus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada menu terdaftar.',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _openFormModal(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Menu Pertama'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    Color categoryColor;
                    switch (item.category.toLowerCase()) {
                      case 'food':
                        categoryColor = AppColors.categoryFood;
                        break;
                      case 'drink':
                        categoryColor = AppColors.categoryDrink;
                        break;
                      default:
                        categoryColor = AppColors.categoryBeverage;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: item.imagePath != null && item.imagePath!.isNotEmpty
                                ? Image.file(
                                    File(item.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    item.category.toLowerCase() == 'drink'
                                        ? Icons.local_drink_rounded
                                        : Icons.restaurant_rounded,
                                    color: Colors.grey[600],
                                  ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(item.price),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  item.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: item.isAvailable ? Colors.green : Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.isAvailable ? 'Tersedia' : 'Habis',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    color: item.isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                                if (item.farmSource != null && item.farmSource!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.eco_rounded, size: 12, color: AppColors.farmBadgeText),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      item.farmSource!,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        color: AppColors.farmBadgeText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _openFormModal(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () => _deleteMenu(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Menu',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MenuFormBottomSheet extends StatefulWidget {
  final MenuItemModel? item;
  final VoidCallback onSave;

  const _MenuFormBottomSheet({this.item, required this.onSave});

  @override
  State<_MenuFormBottomSheet> createState() => _MenuFormBottomSheetState();
}

class _MenuFormBottomSheetState extends State<_MenuFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _farmSourceController = TextEditingController();

  String _category = 'Food';
  bool _isAvailable = true;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descController.text = widget.item!.description;
      _priceController.text = widget.item!.price.toStringAsFixed(0);
      _farmSourceController.text = widget.item!.farmSource ?? '';
      _category = widget.item!.category;
      _isAvailable = widget.item!.isAvailable;
      _imagePath = widget.item!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _farmSourceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = MenuItemModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      category: _category,
      isAvailable: _isAvailable,
      farmSource: _farmSourceController.text.trim().isEmpty ? null : _farmSourceController.text.trim(),
      imagePath: _imagePath,
    );

    if (widget.item != null) {
      await MenuDao().update(updated);
    } else {
      await MenuDao().insert(updated);
    }

    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item != null ? 'Edit Menu Hidangan' : 'Tambah Menu Baru',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Image Picker Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey[150],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkDivider : Colors.grey[300]!,
                      ),
                    ),
                    child: _imagePath != null && _imagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Pilih Foto Hidangan',
                                style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Hidangan *',
                  prefixIcon: Icon(Icons.restaurant_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Price Input
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rupiah) *',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Harga tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori Hidangan',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Drink', child: Text('Drink')),
                  DropdownMenuItem(value: 'Beverage', child: Text('Beverage')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Farm Sourcing Partner
              TextFormField(
                controller: _farmSourceController,
                decoration: const InputDecoration(
                  labelText: 'Mitra Tani Sourcing (Opsional)',
                  hintText: 'Contoh: Komars Hydroponics Center',
                  prefixIcon: Icon(Icons.eco_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Availability Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Ketersediaan Hidangan',
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Aktifkan jika menu siap dipesan oleh pelanggan'),
                value: _isAvailable,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.item != null ? 'Simpan Perubahan' : 'Tambah Hidangan',
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
