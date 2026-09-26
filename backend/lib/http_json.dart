import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Small JSON helpers shared by every route file.

Response jsonResponse(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response errorResponse(String message, {int status = 400}) =>
    jsonResponse({'error': message}, status: status);

/// The request body as a JSON object, or `null` if it's empty/not an object.
Future<Map<String, dynamic>?> readJsonBody(Request request) async {
  try {
    final body = await request.readAsString();
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
