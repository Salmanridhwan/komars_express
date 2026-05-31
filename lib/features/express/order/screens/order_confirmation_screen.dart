import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/notification_helper.dart';
import '../db/order_dao.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderCode;

  const OrderConfirmationScreen({super.key, required this.orderCode});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _orderDao = OrderDao();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderAndTriggerNotification();
  }

  Future<void> _loadOrderAndTriggerNotification() async {
    final order = await _orderDao.getByCode(widget.orderCode);
    if (order != null) {
      // Trigger Local Notification (Assessment Requirement)
      await NotificationHelper.instance.showOrderConfirmedNotification(
        orderCode: order.orderCode,
        totalAmount: order.totalAmount,
      );
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Check Circle
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreenSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Confirmation Title
                    const Text(
                      'Pemesanan Berhasil!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Invoice Code Info
                    Text(
                      'Kode Pesanan: ${widget.orderCode}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subtext description
                    const Text(
                      'Notifikasi konfirmasi pesanan telah dikirim ke perangkat Anda. Silakan tunjukkan kode pesanan ini ke kasir jika memilih pembayaran di kasir, atau tunggu pelayan membawakan makanan Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Buttons navigation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.home,
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Kembali ke Beranda Portal',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.orderHistory,
                          );
                        },
                        child: const Text(
                          'Lihat Riwayat Pesanan',
                          style: TextStyle(
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
