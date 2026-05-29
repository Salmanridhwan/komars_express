class MenuItemModel {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category; // 'Food', 'Drink', 'Beverage'
  final String? imagePath;
  final String? farmSource; // Sourced organic partner from Komars Farm (e.g. 'Komars Hydroponics Center')
  final bool isAvailable;

  const MenuItemModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
    this.farmSource,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_path': imagePath,
        'farm_source': farmSource,
        'is_available': isAvailable ? 1 : 0,
      };

  factory MenuItemModel.fromMap(Map<String, dynamic> map) => MenuItemModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String,
        price: (map['price'] as num).toDouble(),
        category: map['category'] as String,
        imagePath: map['image_path'] as String?,
        farmSource: map['farm_source'] as String?,
        isAvailable: (map['is_available'] as int) == 1,
      );

  MenuItemModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imagePath,
    String? farmSource,
    bool? isAvailable,
  }) =>
      MenuItemModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imagePath: imagePath ?? this.imagePath,
        farmSource: farmSource ?? this.farmSource,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
