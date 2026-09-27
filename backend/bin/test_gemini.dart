import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'YOUR_API_KEY';
  final model = 'gemini-2.5-flash';
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$model:generateContent?key=$apiKey',
  );

  final body = jsonEncode({
    'contents': [
      {'parts': [{'text': 'Hello'}]}
    ]
  });

  print('Sending request...');
  try {
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Status Code: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }
}
