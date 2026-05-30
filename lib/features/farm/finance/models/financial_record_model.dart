class FinancialRecord {
  final int id;
  final int userId;
  final String farmType;
  final String recordDate; // YYYY-MM-DD format
  final double income;
  final double expense;
  final double loss;
  final double netProfit;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  FinancialRecord({
    required this.id,
    required this.userId,
    required this.farmType,
    required this.recordDate,
    required this.income,
    required this.expense,
    required this.loss,
    required this.netProfit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert model to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'farm_type': farmType,
      'record_date': recordDate,
      'income': income,
      'expense': expense,
      'loss': loss,
      'net_profit': netProfit,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create model from database row
  factory FinancialRecord.fromJson(Map<String, dynamic> json) {
    return FinancialRecord(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      farmType: json['farm_type'] as String,
      recordDate: json['record_date'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      loss: (json['loss'] as num).toDouble(),
      netProfit: (json['net_profit'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  // Copy with method for updates
  FinancialRecord copyWith({
    int? id,
    int? userId,
    String? farmType,
    String? recordDate,
    double? income,
    double? expense,
    double? loss,
    double? netProfit,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return FinancialRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmType: farmType ?? this.farmType,
      recordDate: recordDate ?? this.recordDate,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      loss: loss ?? this.loss,
      netProfit: netProfit ?? this.netProfit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
