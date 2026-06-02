import 'package:flutter/material.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import '../models/farm_package_model.dart';
import 'farm_package_form_screen.dart';

class FarmManagementScreen extends StatefulWidget {
  final bool embedded;
  const FarmManagementScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  late DatabaseHelper _dbHelper;
  List<FarmPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _dbHelper = DatabaseHelper.instance;
    await _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    try {
      final dao = _dbHelper.farmPackageDao;
      final packages = await dao.getAllPackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat paket: $e'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    }
  }

  Future<void> _deletePackage(int id) async {
    try {
      final dao = _dbHelper.farmPackageDao;
      await dao.deletePackage(id);
      await _loadPackages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paket berhasil dihapus'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus paket: $e'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(FarmPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.deleteRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.deleteRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Paket?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Paket "${package.title}" akan dihapus secara permanen.',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePackage(package.id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.deleteRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Kelola Paket Investasi',
          style: TextStyle(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmPackageFormScreen(),
            ),
          );
          if (result == true) {
            _loadPackages();
          }
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _packages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.agriculture_rounded, size: 64, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Paket Investasi',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol + untuk menambahkan paket baru.',
                    style: TextStyle(fontFamily: 'Outfit', color: isDark ? AppColors.darkTextSecondary : Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final package = _packages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmPackageFormScreen(package: package),
                          ),
                        );
                        if (result == true) {
                          _loadPackages();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.spa_rounded, color: AppColors.primaryGreen, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          package.title,
                                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryOrange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          package.farmType.toUpperCase(),
                                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondaryOrangeDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    package.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.timer_rounded, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text('${package.harvestTimeDays} Hari', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey[600])),
                                      const SizedBox(width: 12),
                                      Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primaryGreen),
                                      const SizedBox(width: 4),
                                      Text('ROI ${package.roiMonths} Bln', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () {
                                    Future.delayed(Duration.zero, () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FarmPackageFormScreen(package: package),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadPackages();
                                      }
                                    });
                                  },
                                  child: const Text('Edit', style: TextStyle(fontFamily: 'Outfit')),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    Future.delayed(Duration.zero, () => _showDeleteConfirmation(package));
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red, fontFamily: 'Outfit')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );

    if (widget.embedded) {
      return content;
    }
    return content;
  }
}

