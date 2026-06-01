import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/routes/app_routes.dart';
import '../models/farm_package_model.dart';
import 'farm_payment_screen.dart';

class FarmPackageDetailScreen extends StatefulWidget {
  final FarmPackage package;
  final bool? purchased;

  const FarmPackageDetailScreen({
    Key? key,
    required this.package,
    this.purchased,
  }) : super(key: key);

  @override
  State<FarmPackageDetailScreen> createState() =>
      _FarmPackageDetailScreenState();
}

class _FarmPackageDetailScreenState extends State<FarmPackageDetailScreen> {
  bool _isPurchased = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _isPurchased = widget.purchased ?? false;
    _checkPurchaseStatus();
  }

  Future<void> _checkPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    final userId = int.tryParse(token);

    if (mounted) {
      setState(() => _userId = userId);
    }

    if (_isPurchased) return;

    if (userId != null) {
      final db = DatabaseHelper.instance;
      final purchased = await db.purchasedPackageDao.hasPurchased(
        userId,
        widget.package.id,
      );
      if (mounted) {
        setState(() => _isPurchased = purchased);
      }
    }
  }

  Future<void> _navToPayment() async {
    // Pastikan _userId sudah terisi dari _checkPurchaseStatus
    if (_userId == null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
      _userId = int.tryParse(token);
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final success = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.farmPackagePayment,
      arguments: {'package': widget.package, 'userId': _userId!},
    );

    if (success == true && mounted) {
      setState(() => _isPurchased = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Package Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.package.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Farm Type: ${widget.package.farmType}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.package.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Financial Details
            Text(
              'Financial Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Initial Capital (Min)',
              value:
                  'Rp ${widget.package.initialCapitalMin.toStringAsFixed(0)}',
            ),
            _DetailRow(
              label: 'Initial Capital (Recommended)',
              value:
                  'Rp ${widget.package.initialCapitalRec.toStringAsFixed(0)}',
            ),
            _DetailRow(
              label: 'ROI Period',
              value: '${widget.package.roiMonths} months',
            ),
            _DetailRow(
              label: 'Monthly Income (Est.)',
              value: 'Rp ${widget.package.monthlyIncomeEst.toStringAsFixed(0)}',
            ),
            _DetailRow(
              label: 'Harvest Time',
              value: '${widget.package.harvestTimeDays} days',
            ),
            const SizedBox(height: 24),

            if (_isPurchased) ...[
              // Steps
              Text(
                'Implementation Steps',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.package.steps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.package.steps[index],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Equipment List
              Text(
                'Required Equipment',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.package.equipmentList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.package.equipmentList[index],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // Placeholder for non-purchased users
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Panduan Eksklusif Terkunci',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beli paket starter kit ini untuk membuka langkah-langkah pembuatan dan daftar peralatan yang diperlukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _isPurchased
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _navToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Beli Paket Starter Kit',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }

  void _showPurchaseConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi Pembelian',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Anda akan membeli paket "${widget.package.title}" dengan estimasi modal awal Rp ${widget.package.initialCapitalMin.toStringAsFixed(0)}.',
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isPurchased = true);
                      _showSuccessDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Konfirmasi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Berhasil!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paket starter kit telah berhasil dibeli. Silakan cek detail panduan di menu paket Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
