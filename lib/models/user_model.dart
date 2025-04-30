class User {
  final int id;
  final int? cityId;
  final int? stateId;
  final int? countryId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? addressLine1;
  final String? addressLine2;
  final String? emailVerifiedAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.addressLine1,
    this.addressLine2,
    this.cityId,
    this.stateId,
    this.countryId,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'],
      cityId: json['city_id'],
      stateId: json['state_id'],
      countryId: json['country_id'],
      emailVerifiedAt: json['email_verified_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city_id': cityId,
    'state_id': stateId,
    'country_id': countryId,
    'email_verified_at': emailVerifiedAt,
  };
}
