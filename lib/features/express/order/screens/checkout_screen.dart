import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../db/order_dao.dart';
import '../models/cart_manager.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();
  final _orderDao = OrderDao();
  final _cart = CartManager.instance;
  
  String _paymentMethod = 'QRIS'; // 'QRIS' or 'Pay on Site'
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentPreference();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMethod = prefs.getString(PrefKeys.lastPaymentMethod) ?? 'QRIS';
    if (mounted) {
      setState(() {
        _paymentMethod = lastMethod;
      });
    }
  }

  Future<void> _savePaymentPreference(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.lastPaymentMethod, method);
  }

  String _generateOrderCode() {
    final rand = Random();
    final numStr = List.generate(5, (_) => rand.nextInt(10).toString()).join();
    return 'KMRS-$numStr';
  }

  Future<void> _processCheckout() async {
    if (_cart.items.isEmpty) return;

    setState(() => _isCreating = true);

    final orderCode = _generateOrderCode();
    final total = _cart.totalAmount;
    final notes = _notesController.text.trim();
    
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString(PrefKeys.userSessionToken);
    final userId = userIdStr != null ? int.tryParse(userIdStr) ?? 1 : 1; // Fallback to 1 if not found

    // Status is 'Menunggu Pembayaran' if QRIS, otherwise 'Lunas' or 'Menunggu Pembayaran' depending on dine-in rules.
    // Let's mark QRIS as 'Menunggu Pembayaran' and Pay on Site as 'Menunggu Pembayaran' initially.
    final order = OrderModel(
      userId: userId,
      orderCode: orderCode,
      paymentMethod: _paymentMethod,
      totalAmount: total,
      status: 'Menunggu Pembayaran',
      notes: notes.isEmpty ? null : notes,
    );

    final items = _cart.items.map((cartItem) {
      return OrderItemModel(
        menuItemId: cartItem.menuItem.id!,
        quantity: cartItem.quantity,
        unitPrice: cartItem.menuItem.price,
        subtotal: cartItem.subtotal,
      );
    }).toList();

    try {
      final orderId = await _orderDao.createOrder(order, items);
      if (orderId > 0) {
        // Clear cart
        _cart.clear();

        if (mounted) {
          setState(() => _isCreating = false);
          
          if (_paymentMethod == 'QRIS') {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.qrisPayment,
              arguments: orderCode,
            );
          } else {
            // For Pay on Site, we go straight to Confirmation
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.orderConfirmation,
              arguments: orderCode,
            );
          }
        }
      } else {
        throw Exception('Gagal menyimpan pesanan');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartItems = _cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Pesanan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Summary
            const Text(
              'Rincian Pesanan',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.menuItem.name}  x${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Notes / Special Request Form
            const Text(
              'Catatan Tambahan',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Jangan terlalu pedas, kuah dipisah...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Payment Methods Selection (SharedPreferences retrieval/saving)
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              title: 'QRIS (Bayar Instan)',
              subtitle: 'Scan kode QRIS menggunakan e-wallet favoritmu',
              icon: Icons.qr_code_2_rounded,
              value: 'QRIS',
              selectedValue: _paymentMethod,
              onChanged: (val) {
                setState(() => _paymentMethod = val!);
                _savePaymentPreference(val!);
              },
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              title: 'Bayar di Kasir (Pay on Site)',
              subtitle: 'Bayar langsung dengan tunai/kartu di kasir Komars',
              icon: Icons.storefront_rounded,
              value: 'Pay on Site',
              selectedValue: _paymentMethod,
              onChanged: (val) {
                setState(() => _paymentMethod = val!);
                _savePaymentPreference(val!);
              },
            ),
            const SizedBox(height: 32),

            // Final Bill Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Belanja',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 14),
                      ),
                      Text(
                        CurrencyFormatter.format(_cart.totalAmount),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Biaya Layanan',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 14),
                      ),
                      Text(
                        CurrencyFormatter.format(0.0),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        CurrencyFormatter.format(_cart.totalAmount),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isCreating ? null : _processCheckout,
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Buat Pesanan Sekarang',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selectedValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryGreen
              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedValue,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
        secondary: Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
