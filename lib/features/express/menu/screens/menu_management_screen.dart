import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../db/menu_dao.dart';
import '../models/menu_item_model.dart';

class MenuManagementScreen extends StatefulWidget {
  final bool embedded;
  const MenuManagementScreen({super.key, this.embedded = false});

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Menu?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Menu "${item.name}" akan dihapus secara permanen dari daftar.',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await _menuDao.delete(item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.name}" berhasil dihapus'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadAllMenus();
    }
  }

  Future<void> _deleteAllMenus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Semua Menu?'),
        content: const Text(
          'Semua data menu akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _menuDao.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua menu telah dihapus.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildEmbeddedHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Text(
            'Daftar Menu',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (_menuItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              onPressed: _deleteAllMenus,
              tooltip: 'Hapus Semua',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllMenus,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Kelola Menu'),
              actions: [
                if (_menuItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.red,
                    ),
                    onPressed: _deleteAllMenus,
                    tooltip: 'Hapus Semua Menu',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadAllMenus,
                ),
              ],
            ),
      body: Column(
        children: [
          if (widget.embedded) _buildEmbeddedHeader(isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _menuItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _openFormModal(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tambah Menu Pertama'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image / Icon
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.grey[100],
                                  child:
                                      item.imagePath != null &&
                                          item.imagePath!.isNotEmpty
                                      ? (kIsWeb
                                            ? Image.network(
                                                item.imagePath!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: Colors.grey[400],
                                                    ),
                                              )
                                            : Image.file(
                                                File(item.imagePath!),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: Colors.grey[400],
                                                    ),
                                              ))
                                      : Icon(
                                          item.category.toLowerCase() ==
                                                      'drink' ||
                                                  item.category.toLowerCase() ==
                                                      'beverage'
                                              ? Icons.local_drink_rounded
                                              : Icons.restaurant_rounded,
                                          color: Colors.grey[400],
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            item.category.toUpperCase(),
                                            style: TextStyle(
                                              color: categoryColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(item.price),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.primaryGreenLight
                                            : AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          item.isAvailable
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: item.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.isAvailable
                                              ? 'Tersedia'
                                              : 'Habis',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11,
                                            color: item.isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        if (item.farmSource != null &&
                                            item.farmSource!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '• ${item.farmSource!}',
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 11,
                                                color: Colors.grey,
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
                              ),
                              // Action Buttons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _openFormModal(item: item),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _deleteMenu(item),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFormModal(),
        child: const Icon(Icons.add_rounded),
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
  final _categoryController = TextEditingController();
  List<String> _existingCategories = [];
  bool _isAddingNewCategory = false;
  bool _isAvailable = true;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _existingCategories = ['Food', 'Drink', 'Beverage'];
    _isAddingNewCategory = false;

    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descController.text = widget.item!.description;
      _priceController.text = widget.item!.price.toStringAsFixed(0);
      _farmSourceController.text = widget.item!.farmSource ?? '';
      _categoryController.text = widget.item!.category;
      _isAvailable = widget.item!.isAvailable;
      _imagePath = widget.item!.imagePath;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await MenuDao().getCategories();
    if (mounted) {
      setState(() {
        _existingCategories = ['Food', 'Drink', 'Beverage'];
        for (final c in categories) {
          final exists = _existingCategories.any(
            (existing) => existing.toLowerCase() == c.toLowerCase(),
          );
          if (!exists) {
            _existingCategories.add(c);
          }
        }

        if (widget.item != null) {
          final exists = _existingCategories.any(
            (existing) =>
                existing.toLowerCase() == widget.item!.category.toLowerCase(),
          );
          if (!exists) {
            _isAddingNewCategory = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _farmSourceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<String?> _copyImageToCategory(
    String sourcePath,
    String category,
  ) async {
    if (kIsWeb)
      return sourcePath; // Web tidak mendukung akses sistem file lokal

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final categoryFolder = category.toLowerCase().trim();
      final destDir = Directory(p.join(appDir.path, 'menu', categoryFolder));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final destPath = p.join(destDir.path, fileName);
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      return sourcePath; // fallback: gunakan path asli
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imagePath =
            pickedFile.path; // simpan sementara; akan di-copy saat submit
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ FORM VALIDATION FAILED');
      return;
    }

    final category = _categoryController.text.trim().isEmpty
        ? 'Food'
        : _categoryController.text.trim();

    debugPrint('🍔 SUBMITTING MENU: ${_nameController.text}');

    // Jika gambar dipilih dan belum disalin ke folder permanen, salin sekarang
    String? finalImagePath = _imagePath;
    try {
      final isNewImage =
          _imagePath != null &&
          !kIsWeb &&
          !_imagePath!.contains(
            'menu${Platform.pathSeparator}${category.toLowerCase()}',
          ) &&
          !_imagePath!.contains('assets/');

      if (_imagePath != null && isNewImage) {
        finalImagePath = await _copyImageToCategory(_imagePath!, category);
      }
    } catch (e) {
      debugPrint('⚠️ Image copy failed, using original path: $e');
    }

    final updated = MenuItemModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      category: category,
      isAvailable: _isAvailable,
      farmSource: _farmSourceController.text.trim().isEmpty
          ? null
          : _farmSourceController.text.trim(),
      imagePath: finalImagePath,
    );

    try {
      if (widget.item != null) {
        await MenuDao().update(updated);
        debugPrint('✅ Menu updated successfully');
      } else {
        await MenuDao().insert(updated);
        debugPrint('✅ Menu inserted successfully');
      }

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ ERROR SAVING MENU: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan menu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                        color: isDark
                            ? AppColors.darkDivider
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: _imagePath != null && _imagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(
                                    _imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.grey,
                                            ),
                                  )
                                : Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.grey,
                                            ),
                                  ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pilih Foto Hidangan',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
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
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
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
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Harga tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori Hidangan *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in _existingCategories)
                        ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color:
                                  _categoryController.text == cat &&
                                      !_isAddingNewCategory
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                          selectedColor: AppColors.primaryGreen,
                          selected:
                              _categoryController.text == cat &&
                              !_isAddingNewCategory,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _categoryController.text = cat;
                                _isAddingNewCategory = false;
                              });
                            }
                          },
                        ),
                      ChoiceChip(
                        label: const Text(
                          '+ Baru',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _isAddingNewCategory,
                        selectedColor: AppColors.primaryGreenLight,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isAddingNewCategory = true;
                              if (_existingCategories.contains(
                                _categoryController.text,
                              )) {
                                _categoryController.text =
                                    ''; // Clear if they switch from an existing category
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isAddingNewCategory) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori Baru *',
                        hintText: 'Ketik kategori baru (contoh: Snack)',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Kategori tidak boleh kosong'
                          : null,
                    ),
                  ],
                ],
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
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Aktifkan jika menu siap dipesan oleh pelanggan',
                ),
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
                    widget.item != null
                        ? 'Simpan Perubahan'
                        : 'Tambah Hidangan',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                    ),
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
