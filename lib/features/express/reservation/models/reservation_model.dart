class ReservationModel {
  final int? id;
  final int userId;
  final int tableId;
  final String reservationDate; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final String status; // 'Aktif', 'Berlangsung', 'Selesai', 'Dibatalkan'
  final String? notes;
  final String? createdAt;

  // Joined fields (not stored in DB)
  final String? tableNumber;
  final String? tableLocation;

  const ReservationModel({
    this.id,
    required this.userId,
    required this.tableId,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    this.createdAt,
    this.tableNumber,
    this.tableLocation,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'table_id': tableId,
        'reservation_date': reservationDate,
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        'notes': notes,
      };

  factory ReservationModel.fromMap(Map<String, dynamic> map) => ReservationModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        tableId: map['table_id'] as int,
        reservationDate: map['reservation_date'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        status: map['status'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String?,
        tableNumber: map['table_number'] as String?,
        tableLocation: map['location'] as String?,
      );

  ReservationModel copyWith({
    int? id,
    int? userId,
    int? tableId,
    String? reservationDate,
    String? startTime,
    String? endTime,
    String? status,
    String? notes,
    String? createdAt,
    String? tableNumber,
    String? tableLocation,
  }) =>
      ReservationModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tableId: tableId ?? this.tableId,
        reservationDate: reservationDate ?? this.reservationDate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        tableNumber: tableNumber ?? this.tableNumber,
        tableLocation: tableLocation ?? this.tableLocation,
      );
}
