class OrderItemModel {
  final int? id;
  final int? orderId;
  final int menuItemId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  // Join-cached properties for ease of display:
  final String? menuItemName;
  final String? menuItemCategory;

  const OrderItemModel({
    this.id,
    this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.menuItemName,
    this.menuItemCategory,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        id: map['id'] as int?,
        orderId: map['order_id'] as int?,
        menuItemId: map['menu_item_id'] as int,
        quantity: map['quantity'] as int,
        unitPrice: (map['unit_price'] as num).toDouble(),
        subtotal: (map['subtotal'] as num).toDouble(),
        menuItemName: map['menu_name'] as String?,
        menuItemCategory: map['menu_category'] as String?,
      );

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? menuItemId,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    String? menuItemName,
    String? menuItemCategory,
  }) =>
      OrderItemModel(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        menuItemId: menuItemId ?? this.menuItemId,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        subtotal: subtotal ?? this.subtotal,
        menuItemName: menuItemName ?? this.menuItemName,
        menuItemCategory: menuItemCategory ?? this.menuItemCategory,
      );
}
