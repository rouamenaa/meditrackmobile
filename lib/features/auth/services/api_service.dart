import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meditrackmobile/config.dart';
import 'session.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode; // null = pas de réponse du serveur (réseau)
  final dynamic body; // corps JSON de la réponse, si présent

  ApiException(this.message, [this.statusCode, this.body]);

  @override
  String toString() => message;
}

class ApiService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (Session.instance.token != null)
      'Authorization': 'Bearer ${Session.instance.token}',
  };

  Uri _uri(String path) => Uri.parse('$kBaseUrl$path');

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send(
          () => http.post(_uri(path), headers: _headers, body: json.encode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send(
          () => http.put(_uri(path), headers: _headers, body: json.encode(body)));

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  /// Envoie un fichier en multipart/form-data (ex : photo de profil).
  Future<dynamic> postMultipart(String path, String field, String filePath) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (Session.instance.token != null) {
      request.headers['Authorization'] = 'Bearer ${Session.instance.token}';
    }
    request.files.add(await http.MultipartFile.fromPath(field, filePath));

    final http.Response r;
    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      r = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas');
    } on SocketException {
      throw ApiException('Serveur injoignable. Vérifie ta connexion.');
    } on http.ClientException {
      throw ApiException('Serveur injoignable. Vérifie ta connexion.');
    }
    return _decode(r);
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response r;
    try {
      r = await request().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas');
    } on SocketException {
      throw ApiException('Serveur injoignable. Vérifie ta connexion.');
    } on http.ClientException {
      throw ApiException('Serveur injoignable. Vérifie ta connexion.');
    }
    return _decode(r);
  }

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : json.decode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (r.statusCode >= 200 && r.statusCode < 300) return body;

    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Erreur ${r.statusCode}';
    throw ApiException(msg, r.statusCode, body);
  }
}