import 'dart:convert';
import 'package:http/http.dart' as http;

import '../game/xox/factor.dart';

class BackendClient {
  static const String _baseUrl = 'http://localhost:8080';

  static Future<({List<Factor> rows, List<Factor> columns})> fetchBoard() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/xox/generate-board'));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rows = (data['rows'] as List).map((f) => _parseFactor(f)).toList();
      final columns = (data['columns'] as List).map((f) => _parseFactor(f)).toList();
      return (rows: rows, columns: columns);
    } else {
      throw Exception('Failed to load board');
    }
  }

  static Factor _parseFactor(Map<String, dynamic> json) {
    // Basic mapping back to Factor
    final typeStr = json['type'] as String;
    FactorType type;
    if (typeStr.contains('playedLeague')) {
      type = FactorType.playedLeague;
    } else if (typeStr.contains('wonLeague')) {
      type = FactorType.wonLeague;
    } else if (typeStr.contains('wonInternational')) {
      type = FactorType.wonInternational;
    } else if (typeStr.contains('team')) {
      type = FactorType.team;
    } else {
      type = FactorType.nationality;
    }

    return Factor(
      type: type,
      label: json['label'],
      value: json['value'],
    );
  }
}
