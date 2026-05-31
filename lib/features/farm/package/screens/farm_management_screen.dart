import 'package:flutter/material.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import '../models/farm_package_model.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading packages: $e')));
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
          const SnackBar(content: Text('Package deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting package: $e')));
      }
    }
  }

  void _showDeleteConfirmation(FarmPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete "${package.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePackage(package.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showCreateEditDialog({FarmPackage? package}) {
    final titleController = TextEditingController(text: package?.title ?? '');
    final descriptionController = TextEditingController(text: package?.description ?? '');
    final farmTypeController = TextEditingController(text: package?.farmType ?? 'ayam');
    final minCapitalController = TextEditingController(text: package?.initialCapitalMin.toString() ?? '');
    final recCapitalController = TextEditingController(text: package?.initialCapitalRec.toString() ?? '');
    final harvestDaysController = TextEditingController(text: package?.harvestTimeDays.toString() ?? '');
    final roiMonthsController = TextEditingController(text: package?.roiMonths.toString() ?? '');
    final monthlyIncomeController = TextEditingController(text: package?.monthlyIncomeEst.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(package == null ? 'Create Package' : 'Edit Package', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, 'Title'),
              const SizedBox(height: 12),
              _buildTextField(descriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(farmTypeController, 'Farm Type'),
              const SizedBox(height: 12),
              _buildTextField(minCapitalController, 'Min Capital', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(recCapitalController, 'Rec Capital', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(harvestDaysController, 'Harvest Days', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(roiMonthsController, 'ROI Months', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(monthlyIncomeController, 'Monthly Income Est.', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newPackage = FarmPackage(
                  id: package?.id ?? 0,
                  farmType: farmTypeController.text,
                  title: titleController.text,
                  description: descriptionController.text,
                  initialCapitalMin: double.parse(minCapitalController.text),
                  initialCapitalRec: double.parse(recCapitalController.text),
                  harvestTimeDays: int.parse(harvestDaysController.text),
                  roiMonths: int.parse(roiMonthsController.text),
                  monthlyIncomeEst: double.parse(monthlyIncomeController.text),
                  steps: package?.steps ?? [],
                  equipmentList: package?.equipmentList ?? [],
                );

                final dao = _dbHelper.farmPackageDao;
                if (package == null) {
                  await dao.insertPackage(newPackage);
                } else {
                  await dao.updatePackage(newPackage);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        package == null ? 'Package created' : 'Package updated',
                      ),
                    ),
                  );
                  await _loadPackages();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.embedded ? null : AppBar(
        title: const Text('Manage Farm Packages', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Package', style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600)),
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
                    'No Farm Packages Yet',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the button below to add one.',
                    style: TextStyle(fontFamily: 'Outfit', color: Colors.grey[600]),
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
                      onTap: () => _showCreateEditDialog(package: package),
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
                                    Future.delayed(Duration.zero, () => _showCreateEditDialog(package: package));
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

