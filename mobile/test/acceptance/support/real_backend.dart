import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class RealNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = (_) => 'DIRECT';
}

class RealAccount {
  RealAccount(this.token, this.user);
  final String token;
  final Map<String, dynamic> user;
  String get id => user['id'] as String;
  static Future<RealAccount> restore(String profile) async {
    final root = Platform.environment['APPDATA']!;
    final json = jsonDecode(
      await File('$root/com.openmeeting.ai.$profile/server-config.json').readAsString(),
    ) as Map<String, dynamic>;
    final token = json['sessionToken'] as String;
    final dio = Dio(
      BaseOptions(baseUrl: 'http://127.0.0.1:39110', headers: {'Authorization': 'Bearer $token'}),
    );
    try {
      final result = await dio.get<Map<String, dynamic>>('/api/v1/auth/me');
      return RealAccount(token, result.data!);
    } finally {
      dio.close();
    }
  }

  Dio client({String base = 'http://127.0.0.1:39220'}) =>
      Dio(BaseOptions(baseUrl: base, headers: {'Authorization': 'Bearer $token'}));
}

Future<void> fixture(Map<String, Object?> values) async {
  final dio = Dio();
  try {
    await dio.post<void>('http://127.0.0.1:39220/__fixture/mode', data: values);
  } finally {
    dio.close();
  }
}

final artifactRoot = Directory('../Agent测试/Flutter移动会议').absolute;

class Results {
  Results(this.name, {this.io});
  final String name;
  final Future<void> Function(Future<void> Function())? io;
  final rows = <Map<String, Object?>>[];
  Future<void> step(
    String action,
    String expected,
    Future<Object?> Function() run, {
    String? screenshot,
  }) async {
    final start = DateTime.now();
    try {
      final actual = await run();
      rows.add({
        'action': action,
        'expected': expected,
        'actual': actual ?? expected,
        'passed': true,
        'screenshot': screenshot,
        'durationMs': DateTime.now().difference(start).inMilliseconds,
      });
    } catch (error) {
      // Do not serialize Dio exceptions: their request headers may contain credentials.
      rows.add({
        'action': action,
        'expected': expected,
        'actual': error is DioException
            ? 'HTTP ${error.response?.statusCode ?? error.type.name}'
            : error.toString(),
        'passed': false,
        'screenshot': null,
      });
      rethrow;
    } finally {
      Future<void> write() async {
        await File('${artifactRoot.path}/$name.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
      }

      if (io != null) {
        await io!(write);
      } else {
        await write();
      }
      // Structured per-step output for CI and the generated report.
      // ignore: avoid_print
      print(jsonEncode(rows.last));
    }
  }
}
