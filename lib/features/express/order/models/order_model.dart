class OrderModel {
  final int? id;
  final int userId;
  final String orderCode;
  final String paymentMethod; // 'QRIS', 'Pay on Site'
  final double totalAmount;
  final String status; // 'Menunggu Pembayaran', 'Lunas', 'Dibatalkan'
  final String? notes;
  final String? createdAt;

  const OrderModel({
    this.id,
    required this.userId,
    required this.orderCode,
    required this.paymentMethod,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'order_code': orderCode,
        'payment_method': paymentMethod,
        'total_amount': totalAmount,
        'status': status,
        'notes': notes,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        orderCode: map['order_code'] as String,
        paymentMethod: map['payment_method'] as String,
        totalAmount: (map['total_amount'] as num).toDouble(),
        status: map['status'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String?,
      );

  OrderModel copyWith({
    int? id,
    int? userId,
    String? orderCode,
    String? paymentMethod,
    double? totalAmount,
    String? status,
    String? notes,
    String? createdAt,
  }) =>
      OrderModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        orderCode: orderCode ?? this.orderCode,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        totalAmount: totalAmount ?? this.totalAmount,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
