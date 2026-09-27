import 'package:flyball_core/flyball_core.dart';
import 'package:flyball_core/src/ai/gemini_transport.dart';
import 'package:flyball_core/src/ai/board_builder.dart';

void main() async {
  final config = GeminiConfig(
    model: 'gemini-2.5-flash',
    apiKey: 'YOUR_API_KEY',
  );
  final transport = DirectGeminiTransport(config);
  final builder = BoardBuilder(transport);
  
  print('Building board...');
  final board = await builder.buildBoard();
  if (board == null) {
    print('Failed to build board (returned null).');
  } else {
    print('Board built successfully: \${board.rows} x \${board.columns}');
  }
}
