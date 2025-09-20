import '../core/dio_client.dart';
import '../models/user.dart';
import '../models/address.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _dio = DioClient().dio;

  // Get user profile
  Future<User> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch profile');
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;

      final response = await _dio.put('/profile', data: data);
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get('/profile/addresses');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((address) => Address.fromJson(address))
            .toList();
      }
      throw Exception('Failed to fetch addresses');
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  // Add new address
  Future<List<Address>> addAddress(Address address) async {
    try {
      final response = await _dio.post('/profile/addresses', data: address.toJson());
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((addr) => Address.fromJson(addr))
            .toList();
      }
      throw Exception('Failed to add address');
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update address
  Future<List<Address>> updateAddress(String addressId, Address address) async {
    try {
      final response = await _dio.put('/profile/addresses/$addressId', data: address.toJson());
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((addr) => Address.fromJson(addr))
            .toList();
      }
      throw Exception('Failed to update address');
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  Future<List<Address>> deleteAddress(String addressId) async {
    try {
      final response = await _dio.delete('/profile/addresses/$addressId');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((addr) => Address.fromJson(addr))
            .toList();
      }
      throw Exception('Failed to delete address');
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Set default address
  Future<List<Address>> setDefaultAddress(String addressId) async {
    try {
      final response = await _dio.patch('/profile/addresses/$addressId/default');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((addr) => Address.fromJson(addr))
            .toList();
      }
      throw Exception('Failed to set default address');
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }
}
