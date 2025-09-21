class Address {
  final String? id;
  final String type;
  final String name;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String phone;
  final bool isDefault;

  Address({
    this.id,
    required this.type,
    required this.name,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.phone,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id']?.toString(),
      type: json['type']?.toString() ?? 'home',
      name: json['name']?.toString() ?? '',
      line1: json['line1']?.toString() ?? '',
      line2: json['line2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      phone: json['phone']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'type': type,
      'name': name,
      'line1': line1,
      if (line2 != null) 'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? type,
    String? name,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? phone,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get fullAddress {
    final parts = [line1];
    if (line2 != null && line2!.isNotEmpty) {
      parts.add(line2!);
    }
    parts.addAll([city, state, pincode, country]);
    return parts.join(', ');
  }

  String get shortAddress {
    return '$city, $state';
  }
}
