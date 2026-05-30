class TableModel {
  final int? id;
  final String tableNumber;
  final int capacity;
  final String location; // 'Indoor', 'Outdoor', 'VIP'
  final bool isActive;

  const TableModel({
    this.id,
    required this.tableNumber,
    required this.capacity,
    required this.location,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'table_number': tableNumber,
        'capacity': capacity,
        'location': location,
        'is_active': isActive ? 1 : 0,
      };

  factory TableModel.fromMap(Map<String, dynamic> map) => TableModel(
        id: map['id'] as int?,
        tableNumber: map['table_number'] as String,
        capacity: map['capacity'] as int,
        location: map['location'] as String,
        isActive: (map['is_active'] as int) == 1,
      );

  TableModel copyWith({
    int? id,
    String? tableNumber,
    int? capacity,
    String? location,
    bool? isActive,
  }) =>
      TableModel(
        id: id ?? this.id,
        tableNumber: tableNumber ?? this.tableNumber,
        capacity: capacity ?? this.capacity,
        location: location ?? this.location,
        isActive: isActive ?? this.isActive,
      );
}
