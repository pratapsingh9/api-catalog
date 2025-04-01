import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  final sourcesDir = Directory('api_template');
  final generatedDir = Directory('api_json');

  if (!await sourcesDir.exists()) {
    print('Sources directory (${sourcesDir.path}) not found.');
    return;
  }

  // Process all YAML/JSON files under the sources directory.
  await for (var entity in sourcesDir.list(recursive: true, followLinks: false)) {
    if (entity is File && isValidSourceFile(entity)) {
      try {
        // Compute the relative path inside the source directory.
        final relativePath = entity.path.substring(sourcesDir.path.length + 1);
        // Replace the file extension with .json for the output file.
        final newRelativePath = relativePath.replaceAll(RegExp(r'\.(ya?ml)$'), '.json');
        final outputFile = File('${generatedDir.path}/$newRelativePath');

        // Read file content.
        final content = await entity.readAsString();
        // Convert YAML content to JSON format.
        final jsonContent = await convertToJson(content, entity.path);

        // Ensure the output directory exists.
        await outputFile.parent.create(recursive: true);

        // Write pretty-printed JSON to the output file.
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
      // Convert the YAML map to a JSON-serializable format.
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
