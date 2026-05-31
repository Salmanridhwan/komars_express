import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../order/models/cart_manager.dart';
import '../db/menu_dao.dart';
import '../models/menu_item_model.dart';
import '../widgets/menu_card.dart';

class MenuListScreen extends StatefulWidget {
  final bool embedded;
  const MenuListScreen({super.key, this.embedded = false});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final _searchController = TextEditingController();
  final _menuDao = MenuDao();
  
  List<MenuItemModel> _allMenuItems = [];
  List<MenuItemModel> _filteredMenuItems = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    final items = await _menuDao.getAvailable();
    final dbCategories = await _menuDao.getCategories();
    if (mounted) {
      setState(() {
        _allMenuItems = items;
        _filteredMenuItems = items;
        _categories = ['All'];
        _categories.addAll(dbCategories);
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterMenus();
  }

  void _filterMenus() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredMenuItems = _allMenuItems.where((item) {
        final matchesSearch = item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' ||
            item.category.toLowerCase() == _selectedCategory.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterMenus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = CartManager.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Katalog Hidangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari menu favoritmu...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories Horizontal List
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: AppColors.secondaryOrange,
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : Colors.grey[200],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          // Grid Menu Catalog
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMenuItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu_rounded,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Menu tidak ditemukan',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: _filteredMenuItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredMenuItems[index];
                          return MenuCard(
                            item: item,
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.menuDetail,
                                arguments: item,
                              );
                              // Refresh state in case they modified cart in details
                              setState(() {});
                            },
                            onAddToCart: () {
                              cart.addItem(item);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} ditambahkan ke keranjang'),
                                  duration: const Duration(seconds: 1),
                                  action: SnackBarAction(
                                    label: 'KERANJANG',
                                    textColor: AppColors.secondaryOrangeLight,
                                    onPressed: () =>
                                        Navigator.pushNamed(context, AppRoutes.cart),
                                  ),
                                ),
                              );
                              setState(() {}); // refresh floating bar
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // Floating Bottom Cart Bar
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: cart.cartCountNotifier,
        builder: (context, count, child) {
          if (count == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Item Terpilih',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(cart.totalAmount),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  child: const Row(
                    children: [
                      Text(
                        'Keranjang',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
