import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../models/cart_manager.dart';
import '../widgets/cart_drag_handle.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartManager.instance;
  bool _isReorderMode = false;

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggleReorderMode() {
    setState(() => _isReorderMode = !_isReorderMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          if (items.isNotEmpty) ...[
            // Tombol toggle reorder mode (long-press + drag)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                key: ValueKey(_isReorderMode),
                icon: Icon(
                  _isReorderMode
                      ? Icons.check_circle_rounded
                      : Icons.swap_vert_rounded,
                  color: _isReorderMode
                      ? AppColors.secondaryOrange
                      : Colors.grey,
                ),
                onPressed: _toggleReorderMode,
                tooltip: _isReorderMode ? 'Selesai Mengatur' : 'Atur Urutan',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.deleteRed),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Kosongkan Keranjang?'),
                    content: const Text('Apakah Anda yakin ingin menghapus semua item dari keranjang belanja Anda?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deleteRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _cart.clear();
                          Navigator.pop(context);
                          _isReorderMode = false;
                          _refresh();
                        },
                        child: const Text('Kosongkan'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Kosongkan Keranjang',
            ),
          ],
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDark ? AppColors.darkTextHint : Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Keranjang belanjamu kosong',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(180, 48),
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.menuList),
                    child: const Text('Cari Menu Makanan'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Hint banner saat mode reorder aktif
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _isReorderMode ? 36 : 0,
                  color: AppColors.secondaryOrange.withValues(alpha: 0.1),
                  child: _isReorderMode
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_vert_rounded,
                                size: 14, color: AppColors.secondaryOrange),
                            const SizedBox(width: 6),
                            Text(
                              'Tahan & geser (≡) untuk mengubah urutan',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryOrange
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(20),
                    // Mode reorder: aktifkan drag saat long-press
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      _cart.reorder(oldIndex, newIndex);
                      _refresh();
                    },
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final menu = item.menuItem;

                      return Container(
                        key: Key('cart-item-${menu.id}'),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Dismissible(
                          key: Key('dismissible-${menu.id}'),
                          // Nonaktifkan swipe dismiss saat mode reorder agar gesture tidak bertabrakan
                          direction: _isReorderMode
                              ? DismissDirection.none
                              : DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _cart.removeItem(menu);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${menu.name} dihapus dari keranjang')),
                            );
                            _refresh();
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.deleteRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    child: menu.imagePath != null &&
                                            menu.imagePath!.isNotEmpty
                                        ? (kIsWeb ||
                                                menu.imagePath!
                                                    .startsWith('http')
                                            ? Image.network(
                                                menu.imagePath!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons
                                                        .broken_image_rounded),
                                              )
                                            : Image.file(
                                                File(menu.imagePath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons
                                                        .broken_image_rounded),
                                              ))
                                        : Icon(
                                            menu.category.toLowerCase() ==
                                                    'drink'
                                                ? Icons.local_drink_rounded
                                                : Icons.restaurant_rounded,
                                            color: Colors.grey[600],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title and price details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menu.name,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(menu.price),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.primaryGreenLight
                                              : AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Subtotal: ${CurrencyFormatter.format(item.subtotal)}',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity adjustment buttons ATAU Drag Handle
                                if (_isReorderMode)
                                  // Mode reorder: tampilkan drag handle (custom drawn)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: CartDragHandle(
                                      isReorderMode: _isReorderMode,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                    ),
                                  )
                                else
                                  // Mode normal: tampilkan tombol +/-
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _cart.decrementItem(menu);
                                              _refresh();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300]
                                                    ?.withValues(alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.remove,
                                                  size: 20),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _cart.addItem(menu);
                                              _refresh();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add,
                                                  size: 20,
                                                  color: Colors.white),
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
                    },
                  ),
                ),

                // Calculations and Checkout Button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembelian',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Lanjutkan ke Pembayaran',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
