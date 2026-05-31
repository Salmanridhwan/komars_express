import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../db/order_dao.dart';
import '../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool embedded;
  const OrderHistoryScreen({super.key, this.embedded = false});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderDao = OrderDao();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _orderDao.getHistory();
    if (mounted) {
      setState(() {
        _orders = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: Text('Apakah Anda yakin ingin membatalkan pesanan "${order.orderCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Kembali',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Batalkan Pesanan',
              style: TextStyle(color: AppColors.deleteRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && order.id != null) {
      await _orderDao.cancelOrder(order.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesanan ${order.orderCode} berhasil dibatalkan')),
      );
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 80,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum Ada Pesanan',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kelihatannya Anda belum memesan apapun. Yuk, jelajahi menu lezat kami dan mulai pesanan pertama Anda!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.embedded) {
                                // If embedded in navbar, it's a bit tricky to change the navbar index from here without a global state,
                                // but we can push the menu list route instead.
                                Navigator.pushNamed(context, AppRoutes.menuList);
                              } else {
                                Navigator.pushNamed(context, AppRoutes.menuList);
                              }
                            },
                            child: const Text('Mulai Pesan Sekarang'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    
                    // Map statuses to BadgeType
                    String statusText = "";
                    switch (order.status) {
                      case 'Lunas':
                        statusText = "Selesai";
                        break;
                      case 'Dibatalkan':
                        statusText = "Dibatalkan";
                        break;
                      default:
                        statusText = "Menunggu Pembayaran";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.orderDetail,
                            arguments: order,
                          );
                          _loadHistory();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              order.orderCode,
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            StatusBadge(status: statusText),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${(order.createdAt != null && order.createdAt!.length >= 16) ? order.createdAt!.substring(0, 16).replaceAll('T', ' ') : (order.createdAt ?? '-')} • ${order.paymentMethod}',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: AppColors.lightDivider),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Belanja',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(order.totalAmount),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order.status == 'Menunggu Pembayaran')
                                    SizedBox(
                                      height: 32,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.deleteRed,
                                          side: const BorderSide(color: AppColors.deleteRed),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _cancelOrder(order),
                                        child: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
