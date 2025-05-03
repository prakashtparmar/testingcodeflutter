class TourDetails {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  TourDetails({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TourDetails.fromJson(Map<String, dynamic> json) {
    return TourDetails(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
