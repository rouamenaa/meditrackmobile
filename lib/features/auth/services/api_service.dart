import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meditrackmobile/config.dart';
import 'session.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode; // null = pas de réponse du serveur (réseau)
  ApiException(this.message, [this.statusCode]);

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
    throw ApiException(msg, r.statusCode);
  }
}