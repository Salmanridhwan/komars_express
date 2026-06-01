class HarvestSale {
  final int? id;
  final int farmerUserId;
  final int mitraId;
  final String mitraName;
  final String farmType;
  final String harvestName;
  final double quantityKg;
  final double pricePerKg;
  final double totalPrice;
  final String status; // 'Menunggu', 'Diterima', 'Ditolak'
  final String? notes;
  final String? farmerName; // populated via join
  final String? createdAt;
  final String? updatedAt;

  const HarvestSale({
    this.id,
    required this.farmerUserId,
    required this.mitraId,
    required this.mitraName,
    required this.farmType,
    required this.harvestName,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.farmerName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'farmer_user_id': farmerUserId,
        'mitra_id': mitraId,
        'mitra_name': mitraName,
        'farm_type': farmType,
        'harvest_name': harvestName,
        'quantity_kg': quantityKg,
        'price_per_kg': pricePerKg,
        'total_price': totalPrice,
        'status': status,
        'notes': notes,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
      };

  factory HarvestSale.fromJson(Map<String, dynamic> json) => HarvestSale(
        id: json['id'] as int?,
        farmerUserId: json['farmer_user_id'] as int,
        mitraId: json['mitra_id'] as int,
        mitraName: json['mitra_name'] as String,
        farmType: json['farm_type'] as String,
        harvestName: json['harvest_name'] as String,
        quantityKg: (json['quantity_kg'] as num).toDouble(),
        pricePerKg: (json['price_per_kg'] as num).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
        status: json['status'] as String,
        notes: json['notes'] as String?,
        farmerName: json['farmer_name'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  HarvestSale copyWith({
    int? id,
    int? farmerUserId,
    int? mitraId,
    String? mitraName,
    String? farmType,
    String? harvestName,
    double? quantityKg,
    double? pricePerKg,
    double? totalPrice,
    String? status,
    String? notes,
    String? farmerName,
    String? createdAt,
    String? updatedAt,
  }) =>
      HarvestSale(
        id: id ?? this.id,
        farmerUserId: farmerUserId ?? this.farmerUserId,
        mitraId: mitraId ?? this.mitraId,
        mitraName: mitraName ?? this.mitraName,
        farmType: farmType ?? this.farmType,
        harvestName: harvestName ?? this.harvestName,
        quantityKg: quantityKg ?? this.quantityKg,
        pricePerKg: pricePerKg ?? this.pricePerKg,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        farmerName: farmerName ?? this.farmerName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
