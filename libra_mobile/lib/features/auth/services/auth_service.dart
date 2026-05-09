import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  // Register a new user
  // Returns the UserModel on success, throws exception on failure

  Future<UserModel> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {'email': email, 'name': name, 'password': password},
    );

    // Save tokens returned from register

    await TokenStorage.saveTokens(
      access: response.data['tokens']['access'],
      refresh: response.data['tokens']['refresh'],
    );
    return UserModel.fromJson(response.data['user']);
  }

  // Login with email and password

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    // Save tokens returned from login

    await TokenStorage.saveTokens(
      access: response.data['access'],
      refresh: response.data['refresh'],
    );

    await Future.delayed(const Duration(milliseconds: 300));

    // Fetch the user profile after login

    return await getProfile();
  }

  // Get current user profile

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return UserModel.fromJson(response.data);
  }

  // Logout — clear tokens from device

  Future<void> logout() async {
    await TokenStorage.clearTokens();
  }
}
