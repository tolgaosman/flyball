import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openAssetDatabase() async {
  // In the backend, we just read the frontend's asset database directly.
  final currentDir = Directory.current.path;
  final path = p.normalize(p.join(currentDir, '..', 'frontend', 'assets', 'db', 'players.db'));
  
  if (!await File(path).exists()) {
    throw Exception('Database not found at $path. Please run from the backend directory.');
  }
  
  print('[PlayerDB] Opening database at $path');
  return databaseFactory.openDatabase(path);
}
