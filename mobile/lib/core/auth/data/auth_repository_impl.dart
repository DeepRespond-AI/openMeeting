import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/endpoints.dart';
import '../../api/models/auth_models.dart';
import '../domain/auth_repository.dart';
import 'client_info_source.dart';

part 'auth_repository_impl.g.dart';

class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._dio, this._clientInfo);

  final Dio _dio;
  final Future<ClientInfo> Function() _clientInfo;

  @override
  Future<AuthConfig> fetchAuthConfig() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.authConfig);
    return AuthConfig.fromJson(res.data!);
  });

  @override
  Future<SendCodeResult> sendCode({required String phone, required AuthPurpose purpose}) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.authSendCode,
          data: {'phone': phone, 'purpose': purpose.wire},
        );
        return SendCodeResult.fromJson(res.data!);
      });

  @override
  Future<AuthResult> login({required String phone, required String code}) => apiCall(() async {
    final client = await _clientInfo();
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.authLogin,
      data: {'phone': phone, 'code': code, 'client': client.toJson()},
    );
    return AuthResult.fromJson(res.data!);
  });

  @override
  Future<AuthResult> loginWithPassword({required String phone, required String password}) =>
      apiCall(() async {
        final client = await _clientInfo();
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.authLogin,
          data: {'phone': phone, 'password': password, 'client': client.toJson()},
        );
        return AuthResult.fromJson(res.data!);
      });

  @override
  Future<AuthResult> register({
    required String phone,
    required String code,
    required String name,
    required String password,
  }) => apiCall(() async {
    final client = await _clientInfo();
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.authRegister,
      data: {
        'phone': phone,
        'code': code,
        'name': name,
        'password': password,
        'client': client.toJson(),
      },
    );
    return AuthResult.fromJson(res.data!);
  });

  @override
  Future<AuthResult> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) => apiCall(() async {
    final client = await _clientInfo();
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.authPasswordReset,
      data: {'phone': phone, 'code': code, 'password': password, 'client': client.toJson()},
    );
    return AuthResult.fromJson(res.data!);
  });

  @override
  Future<void> logout({required String token}) => apiCall(() async {
    await _dio.post<void>(
      Endpoints.authLogout,
      options: Options(headers: {AuthHeader.name: AuthHeader.bearer(token)}),
    );
  });

  @override
  Future<User> me() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.authMe);
    return User.fromJson(res.data!);
  });

  @override
  Future<User> updateName(String name) => apiCall(() async {
    final res = await _dio.patch<Map<String, dynamic>>(Endpoints.authMe, data: {'name': name});
    return User.fromJson(res.data!);
  });

  @override
  Future<User> changePassword({String? oldPassword, required String password}) => apiCall(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      Endpoints.authMePassword,
      data: {'old_password': oldPassword, 'password': password},
    );
    return User.fromJson(res.data!);
  });
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    DioAuthRepository(ref.watch(apiClientProvider), () => ref.read(clientInfoProvider.future));
