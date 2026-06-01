class MitraPartnership {
  final int? id;
  final String mitraName;
  final String companyName;
  final String category;
  final String contact;
  final String joinedDate;
  final bool isActive;
  final String? description;
  final String? logoIcon; // icon identifier

  const MitraPartnership({
    this.id,
    required this.mitraName,
    required this.companyName,
    required this.category,
    required this.contact,
    required this.joinedDate,
    this.isActive = true,
    this.description,
    this.logoIcon,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'mitra_name': mitraName,
        'company_name': companyName,
        'category': category,
        'contact': contact,
        'joined_date': joinedDate,
        'is_active': isActive ? 1 : 0,
        'description': description,
        'logo_icon': logoIcon,
      };

  factory MitraPartnership.fromJson(Map<String, dynamic> json) =>
      MitraPartnership(
        id: json['id'] as int?,
        mitraName: json['mitra_name'] as String,
        companyName: json['company_name'] as String,
        category: json['category'] as String,
        contact: json['contact'] as String,
        joinedDate: json['joined_date'] as String,
        isActive: (json['is_active'] as int) == 1,
        description: json['description'] as String?,
        logoIcon: json['logo_icon'] as String?,
      );

  MitraPartnership copyWith({
    int? id,
    String? mitraName,
    String? companyName,
    String? category,
    String? contact,
    String? joinedDate,
    bool? isActive,
    String? description,
    String? logoIcon,
  }) =>
      MitraPartnership(
        id: id ?? this.id,
        mitraName: mitraName ?? this.mitraName,
        companyName: companyName ?? this.companyName,
        category: category ?? this.category,
        contact: contact ?? this.contact,
        joinedDate: joinedDate ?? this.joinedDate,
        isActive: isActive ?? this.isActive,
        description: description ?? this.description,
        logoIcon: logoIcon ?? this.logoIcon,
      );
}
