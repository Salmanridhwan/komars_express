import 'package:flutter/material.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/features/farm/package/models/purchased_package_model.dart';
import 'package:intl/intl.dart';
import 'farm_package_detail_screen.dart';

class MyPackagesScreen extends StatefulWidget {
  final int userId;

  const MyPackagesScreen({super.key, required this.userId});

  @override
  State<MyPackagesScreen> createState() => _MyPackagesScreenState();
}

class _MyPackagesScreenState extends State<MyPackagesScreen> {
  final _purchasedDao = DatabaseHelper.instance.purchasedPackageDao;
  List<PurchasedPackage>? _purchasedList;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _purchasedDao.getPurchasedByUserId(widget.userId);
    if (mounted) {
      setState(() => _purchasedList = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paket Saya',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _purchasedList == null
          ? const Center(child: CircularProgressIndicator())
          : _purchasedList!.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _purchasedList!.length,
                itemBuilder: (context, index) {
                  final item = _purchasedList![index];
                  return _buildPackageCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada paket yang dibeli',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beli paket starter kit untuk memulai bertani!',
            style: TextStyle(fontFamily: 'Outfit', color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cari Paket'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PurchasedPackage item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final date = DateTime.parse(item.purchaseDate);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          if (item.package != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FarmPackageDetailScreen(
                  package: item.package!,
                  purchased: true,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: AppColors.secondaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.package?.title ?? 'Unknown Package',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${item.package?.farmType.toUpperCase()} • $formattedDate',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Aktif',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        item.paymentMethod,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Harga Beli',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        currencyFormat.format(item.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
