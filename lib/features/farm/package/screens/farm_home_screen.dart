import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import '../models/farm_package_model.dart';
import 'farm_package_detail_screen.dart';
import 'farm_management_screen.dart';

class FarmHomeScreen extends StatefulWidget {
  const FarmHomeScreen({Key? key}) : super(key: key);

  @override
  State<FarmHomeScreen> createState() => _FarmHomeScreenState();
}

class _FarmHomeScreenState extends State<FarmHomeScreen> {
  late SharedPreferences _prefs;
  late DatabaseHelper _dbHelper;
  String _selectedFarmType = 'ayam';
  List<FarmPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _prefs = await SharedPreferences.getInstance();
    _dbHelper = DatabaseHelper.instance;

    // Load saved farm type preference
    _selectedFarmType = _prefs.getString(PrefKeys.selectedFarmType) ?? 'ayam';

    // Load packages
    await _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    try {
      final dao = _dbHelper.farmPackageDao;
      final packages = await dao.getPackagesByFarmType(_selectedFarmType);
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

  Future<void> _saveFarmTypePreference(String farmType) async {
    await _prefs.setString(PrefKeys.selectedFarmType, farmType);
    setState(() => _selectedFarmType = farmType);
    await _loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komars Farm'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmManagementScreen(),
                ),
              ).then((_) => _loadPackages());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Type Selector
                  Text(
                    'Select Farm Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['ayam', 'lele', 'hidroponik', 'sayuran']
                          .map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(type),
                                selected: _selectedFarmType == type,
                                onSelected: (selected) {
                                  if (selected) {
                                    _saveFarmTypePreference(type);
                                  }
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Packages List
                  Text(
                    'Available Packages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _packages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No packages available',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.agriculture,
                                    color: Colors.green.shade700,
                                    size: 32,
                                  ),
                                ),
                                title: Text(package.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'ROI: ${package.roiMonths} months',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Capital: Rp ${package.initialCapitalMin.toStringAsFixed(0)} - Rp ${package.initialCapitalRec.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FarmPackageDetailScreen(
                                            package: package,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

