import 'dart:convert';

class FarmPackage {
  final int id;
  final String farmType;
  final String title;
  final String description;
  final double initialCapitalMin;
  final double initialCapitalRec;
  final int harvestTimeDays;
  final int roiMonths;
  final double monthlyIncomeEst;
  final List<String> steps;
  final List<String> equipmentList;

  FarmPackage({
    required this.id,
    required this.farmType,
    required this.title,
    required this.description,
    required this.initialCapitalMin,
    required this.initialCapitalRec,
    required this.harvestTimeDays,
    required this.roiMonths,
    required this.monthlyIncomeEst,
    required this.steps,
    required this.equipmentList,
  });

  // Convert model to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_type': farmType,
      'title': title,
      'description': description,
      'initial_capital_min': initialCapitalMin,
      'initial_capital_rec': initialCapitalRec,
      'harvest_time_days': harvestTimeDays,
      'roi_months': roiMonths,
      'monthly_income_est': monthlyIncomeEst,
      'steps': jsonEncode(steps),
      'equipment_list': jsonEncode(equipmentList),
    };
  }

  // Create model from database row
  factory FarmPackage.fromJson(Map<String, dynamic> json) {
    return FarmPackage(
      id: json['id'] as int,
      farmType: json['farm_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      initialCapitalMin: (json['initial_capital_min'] as num).toDouble(),
      initialCapitalRec: (json['initial_capital_rec'] as num).toDouble(),
      harvestTimeDays: json['harvest_time_days'] as int,
      roiMonths: json['roi_months'] as int,
      monthlyIncomeEst: (json['monthly_income_est'] as num).toDouble(),
      steps: json['steps'] != null
          ? List<String>.from(jsonDecode(json['steps'] as String) as List)
          : [],
      equipmentList: json['equipment_list'] != null
          ? List<String>.from(
              jsonDecode(json['equipment_list'] as String) as List,
            )
          : [],
    );
  }

  // Copy with method for updates
  FarmPackage copyWith({
    int? id,
    String? farmType,
    String? title,
    String? description,
    double? initialCapitalMin,
    double? initialCapitalRec,
    int? harvestTimeDays,
    int? roiMonths,
    double? monthlyIncomeEst,
    List<String>? steps,
    List<String>? equipmentList,
  }) {
    return FarmPackage(
      id: id ?? this.id,
      farmType: farmType ?? this.farmType,
      title: title ?? this.title,
      description: description ?? this.description,
      initialCapitalMin: initialCapitalMin ?? this.initialCapitalMin,
      initialCapitalRec: initialCapitalRec ?? this.initialCapitalRec,
      harvestTimeDays: harvestTimeDays ?? this.harvestTimeDays,
      roiMonths: roiMonths ?? this.roiMonths,
      monthlyIncomeEst: monthlyIncomeEst ?? this.monthlyIncomeEst,
      steps: steps ?? this.steps,
      equipmentList: equipmentList ?? this.equipmentList,
    );
  }
}
