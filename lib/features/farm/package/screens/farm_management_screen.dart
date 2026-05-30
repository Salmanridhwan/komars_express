import 'package:flutter/material.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../models/farm_package_model.dart';

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({Key? key}) : super(key: key);

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

  void _showCreateEditDialog({FarmPackage? package}) {
    final titleController = TextEditingController(text: package?.title ?? '');
    final descriptionController = TextEditingController(
      text: package?.description ?? '',
    );
    final farmTypeController = TextEditingController(
      text: package?.farmType ?? 'ayam',
    );
    final minCapitalController = TextEditingController(
      text: package?.initialCapitalMin.toString() ?? '',
    );
    final recCapitalController = TextEditingController(
      text: package?.initialCapitalRec.toString() ?? '',
    );
    final harvestDaysController = TextEditingController(
      text: package?.harvestTimeDays.toString() ?? '',
    );
    final roiMonthsController = TextEditingController(
      text: package?.roiMonths.toString() ?? '',
    );
    final monthlyIncomeController = TextEditingController(
      text: package?.monthlyIncomeEst.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(package == null ? 'Create Package' : 'Edit Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: farmTypeController,
                decoration: const InputDecoration(labelText: 'Farm Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minCapitalController,
                decoration: const InputDecoration(labelText: 'Min Capital'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recCapitalController,
                decoration: const InputDecoration(labelText: 'Rec Capital'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: harvestDaysController,
                decoration: const InputDecoration(labelText: 'Harvest Days'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roiMonthsController,
                decoration: const InputDecoration(labelText: 'ROI Months'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income Est.',
                ),
                keyboardType: TextInputType.number,
              ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Packages'), elevation: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No packages found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final package = _packages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(package.title),
                    subtitle: Text(package.farmType),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () {
                            Future.delayed(Duration.zero, () {
                              _showCreateEditDialog(package: package);
                            });
                          },
                          child: const Text('Edit'),
                        ),
                        PopupMenuItem(
                          onTap: () {
                            Future.delayed(Duration.zero, () {
                              _showDeleteConfirmation(package);
                            });
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

