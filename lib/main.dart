import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
// aa
Future<void> main() async {
  final sourcesDir = Directory('api_template');
  final generatedDir = Directory('api_json');

  if (!await sourcesDir.exists()) {
    print('Sources directory (${sourcesDir.path}) not found.');
    return;
  }
//a
  await for (var entity in sourcesDir.list(recursive: true, followLinks: false)) {
    if (entity is File && isValidSourceFile(entity)) {
      try {
        final relativePath = entity.path.substring(sourcesDir.path.length + 1);
        final newRelativePath = relativePath.replaceAll(RegExp(r'\.(ya?ml)$'), '.json');
        final outputFile = File('${generatedDir.path}/$newRelativePath');
        final content = await entity.readAsString();
        final jsonContent = await convertToJson(content, entity.path);
        await outputFile.parent.create(recursive: true);
        final encoder = JsonEncoder.withIndent('  ');
        await outputFile.writeAsString(encoder.convert(jsonContent));

        print('Converted ${entity.path} to ${outputFile.path}');
      } catch (e) {
        print('Error processing ${entity.path}: $e');
      }
    }
  }
}

bool isValidSourceFile(File file) {
  final path = file.path.toLowerCase();
  return path.endsWith('.yaml') || path.endsWith('.yml') || path.endsWith('.json');
}

Future<dynamic> convertToJson(String content, String path) async {
  try {
    if (isYaml(path)) {
      final yamlMap = loadYaml(content);
      return jsonDecode(jsonEncode(yamlMap));
    }
    return jsonDecode(content);
  } catch (e) {
    throw FormatException('Failed to parse file: ${e.toString()}');
  }
}

bool isYaml(String path) {
  return path.toLowerCase().endsWith('.yaml') || path.toLowerCase().endsWith('.yml');
}
