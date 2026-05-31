import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../order/models/cart_manager.dart';
import '../models/menu_item_model.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItemModel item;

  const MenuDetailScreen({super.key, required this.item});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int _quantity = 1;

  void _increment() {
    setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() {
    final cart = CartManager.instance;
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(widget.item);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity ${widget.item.name} berhasil ditambahkan'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color categoryColor;
    switch (widget.item.category.toLowerCase()) {
      case 'food':
        categoryColor = AppColors.categoryFood;
        break;
      case 'drink':
        categoryColor = AppColors.categoryDrink;
        break;
      default:
        categoryColor = AppColors.categoryBeverage;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Hero image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'menu-image-${widget.item.id}',
                child: Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child:
                      widget.item.imagePath != null &&
                          widget.item.imagePath!.isNotEmpty
                      ? (kIsWeb || widget.item.imagePath!.startsWith('http'))
                            ? Image.network(
                                widget.item.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                            : Image.file(
                                File(widget.item.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                      : Center(
                          child: Icon(
                            widget.item.category.toLowerCase() == 'drink'
                                ? Icons.local_drink_rounded
                                : Icons.restaurant_rounded,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Detail Info
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Category & Farm Sourcing
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.category.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.item.farmSource != null &&
                          widget.item.farmSource!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.farmBadgeBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.farmBadgeBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                size: 12,
                                color: AppColors.farmBadgeText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.farmSource!,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.farmBadgeText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Menu Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.item.price),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.primaryGreenLight
                              : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Deskripsi Hidangan',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Farm Sourcing Box (Assessment highlights)
                  if (widget.item.farmSource != null &&
                      widget.item.farmSource!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.primaryGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.agriculture_rounded,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Konsep Farm-to-Table',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primaryGreenDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Menu ini dipasok secara berkelanjutan oleh mitra agribisnis kami "${widget.item.farmSource}". Setiap gigitan mendukung petani lokal dan menjamin kesegaran 100%!',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Spacer(),

                  // Bottom Quantity Counter & Action Button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded),
                              onPressed: _decrement,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: _increment,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: widget.item.isAvailable
                              ? _addToCart
                              : null,
                          child: Text(
                            widget.item.isAvailable
                                ? 'Tambah ke Keranjang'
                                : 'Stok Habis',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
