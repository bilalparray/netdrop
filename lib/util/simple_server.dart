import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef RouteHandler = Future<void> Function(HttpRequest request);

class SimpleServerRoute {
  const SimpleServerRoute({
    required this.method,
    required this.path,
    required this.handler,
  });

  final String method;
  final String path;
  final RouteHandler handler;
}

class SimpleServer {
  SimpleServer(this._routes);

  final List<SimpleServerRoute> _routes;

  Future<void> handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      final method = request.method.toUpperCase();

      for (final route in _routes) {
        if (route.method == method && route.path == path) {
          await route.handler(request);
          return;
        }
      }

      await _writeJson(request, HttpStatus.notFound, {'message': 'Not found'});
    } catch (error) {
      await _writeJson(request, HttpStatus.internalServerError, {'message': '$error'});
    }
  }

  static Future<String> readBody(HttpRequest request) async {
    return await utf8.decoder.bind(request).join();
  }

  static Future<void> writeJson(HttpRequest request, int status, Object body) async {
    await _writeJson(request, status, body);
  }

  static Future<void> writeEmpty(HttpRequest request, int status) async {
    request.response.statusCode = status;
    await request.response.close();
  }

  static Future<void> _writeJson(HttpRequest request, int status, Object body) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}
