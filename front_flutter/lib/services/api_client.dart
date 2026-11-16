import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/upload_file.dart';

import 'browser_platform.dart'
    if (dart.library.js_interop) 'browser_platform_web.dart'
    as browser;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    http.Client? client,
    String? Function()? readXsrfToken,
  }) : _baseUri = baseUrl.isEmpty ? Uri.base : Uri.parse(baseUrl),
       _client = client ?? browser.createHttpClient(),
       _readXsrfToken = readXsrfToken ?? browser.readXsrfToken;

  final Uri _baseUri;
  final http.Client _client;
  final String? Function() _readXsrfToken;
  Future<void>? _sessionInitialization;

  Future<void> initializeSession() =>
      _sessionInitialization ??= _initializeSession();

  Future<void> _initializeSession() async {
    try {
      await _perform('GET', '/sanctum/csrf-cookie');
    } catch (_) {
      _sessionInitialization = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    await initializeSession();
    return _requirePayload(await _perform('GET', path, query: query));
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async => _requirePayload(await _write('POST', path, body: body));

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async => _requirePayload(await _write('PATCH', path, body: body));

  Future<void> delete(String path) async {
    await _write('DELETE', path);
  }

  Future<Map<String, dynamic>?> _write(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _withCsrf(
      (headers) => _perform(method, path, body: body, headers: headers),
    );
  }

  Future<Map<String, dynamic>> upload(
    String path, {
    required Map<String, dynamic> values,
    required UploadFile file,
    bool update = false,
  }) async {
    return _requirePayload(
      await _withCsrf((headers) {
        final request = http.MultipartRequest('POST', _baseUri.resolve(path))
          ..headers.addAll({'Accept': 'application/json', ...headers});
        for (final entry in values.entries) {
          request.fields[entry.key] = entry.value == null
              ? ''
              : entry.value is bool
              ? (entry.value == true ? '1' : '0')
              : entry.value.toString();
        }
        if (update) request.fields['_method'] = 'PATCH';
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover_image',
            file.bytes,
            filename: file.name,
          ),
        );
        return _send(request);
      }),
    );
  }

  Future<Map<String, dynamic>?> _withCsrf(
    Future<Map<String, dynamic>?> Function(Map<String, String>) send,
  ) async {
    await initializeSession();
    for (var attempt = 0; attempt < 2; attempt++) {
      await _perform('GET', '/sanctum/csrf-cookie');
      final token = _readXsrfToken();
      try {
        return await send({'X-XSRF-TOKEN': ?token});
      } on ApiException catch (error) {
        if (error.statusCode != 419 || attempt == 1) rethrow;
      }
    }
    throw const ApiException(
      'Não foi possível validar a sessão. Atualize a página.',
    );
  }

  Map<String, dynamic> _requirePayload(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw const ApiException('A API retornou uma resposta inválida.');
    }
    return payload;
  }

  Future<Map<String, dynamic>?> _perform(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll({'Accept': 'application/json', ...headers});
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    return _send(request);
  }

  Future<Map<String, dynamic>?> _send(http.BaseRequest request) async {
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      Map<String, dynamic>? payload;
      if (response.bodyBytes.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) payload = decoded;
        } on FormatException {
          payload = null;
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _responseError(response.statusCode, payload);
      }
      if (response.statusCode == 204) return null;
      return _requirePayload(payload);
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar à loja. Confira se a API está funcionando.',
      );
    } on TimeoutException {
      throw const ApiException(
        'A loja demorou para responder. Tente novamente.',
      );
    }
  }

  ApiException _responseError(int status, Map<String, dynamic>? payload) {
    final errors = <String, List<String>>{};
    final validation = payload?['errors'];
    if (validation is Map<String, dynamic>) {
      for (final entry in validation.entries) {
        if (entry.value is List) {
          errors[entry.key] = (entry.value as List)
              .whereType<String>()
              .toList();
        }
      }
    }
    final message = switch (status) {
      401 => 'Entre na sua conta para continuar.',
      403 => 'Você não tem permissão para realizar esta ação.',
      404 => 'O item não foi encontrado ou está indisponível.',
      419 => 'Sua sessão expirou. Atualize a página e tente novamente.',
      429 => 'Muitas tentativas. Aguarde um minuto e tente novamente.',
      >= 500 => 'Não foi possível concluir a solicitação. Tente novamente.',
      _ =>
        payload?['message'] as String? ??
            'Não foi possível concluir a solicitação.',
    };
    return ApiException(message, statusCode: status, errors: errors);
  }

  void close() => _client.close();
}
