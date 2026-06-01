import 'farm_package_model.dart';

class PurchasedPackage {
  final int? id;
  final int userId;
  final int packageId;
  final String purchaseDate;
  final String paymentMethod;
  final double price;
  final String status;
  final FarmPackage? package; // Joined data

  PurchasedPackage({
    this.id,
    required this.userId,
    required this.packageId,
    required this.purchaseDate,
    required this.paymentMethod,
    required this.price,
    this.status = 'Success',
    this.package,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'package_id': packageId,
      'purchase_date': purchaseDate,
      'payment_method': paymentMethod,
      'price': price,
      'status': status,
    };
    if (id != null) data['id'] = id;
    return data;
  }

  factory PurchasedPackage.fromJson(Map<String, dynamic> json) {
    return PurchasedPackage(
      id: json['purchase_id'] as int?,
      userId: json['user_id'] as int,
      packageId: json['package_id'] as int,
      purchaseDate: json['purchase_date'] as String,
      paymentMethod: json['payment_method'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String? ?? 'Success',
      package: json['farm_type'] != null ? FarmPackage.fromJson(json) : null,
    );
  }
}
