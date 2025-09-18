class Address {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  Address({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final List<Address> addresses;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.addresses,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'user',
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((address) => Address.fromJson(address))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'addresses': addresses.map((address) => address.toJson()).toList(),
    };
  }
}
