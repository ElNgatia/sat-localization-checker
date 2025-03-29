import 'dart:io';
import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:loc_checker/generator/arb_generator.dart';
import 'package:loc_checker/helpers/localized_keys.dart';
import 'package:loc_checker/helpers/string_filters.dart';
import 'package:loc_checker/models/models.dart';
import 'package:path/path.dart' as path;

import 'ast_visitor.dart';
import 'config.dart';

class LocalizationChecker {
  final LocalizationCheckerConfig config;
  final LocalizedKeysFinder keysFinder;
  final StringFilter stringFilter;
  final List<NonLocalizedString> _results = [];

  LocalizationChecker({
    this.config,
    LocalizedKeysFinder keysFinder,
    StringFilter stringFilter,
  })  : keysFinder = keysFinder ?? LocalizedKeysFinder(config),
        stringFilter = stringFilter ?? StringFilter(config);

  List<NonLocalizedString> get results => _results;

  Future<void> run({bool generateArb = false, String arbOutputDir}) async {
    await keysFinder.findLocalizedKeys();
    await _scanDartFiles();
    if (generateArb) {
      final outputDir = arbOutputDir ?? config.projectPath;
      ArbGenerator(outputDir: outputDir, verbose: config.verbose).generateArbFile(_results);
    }
  }

  Future<void> _scanDartFiles() async {
    final fileSystem = LocalFileSystem();
    final files = await _collectDartFiles(fileSystem);
    await _processFilesInBatches(files);
  }

  Future<List<File>> _collectDartFiles(LocalFileSystem fileSystem) async {
    final filesToProcess = <File>[];
    if (config.verbose) _logConfig();

    for (final scanPath in config.scanPaths) {
      final normalizedPath = path.normalize(scanPath);
      if (!Directory(normalizedPath).existsSync()) {
        if (config.verbose) print('Warning: Directory not found: $normalizedPath');
        continue;
      }

      final dartFiles = await _globDartFiles(fileSystem, normalizedPath);
      filesToProcess.addAll(_filterExcludedFiles(dartFiles));
    }

    if (config.verbose) _logFiles(filesToProcess);
    return filesToProcess;
  }

  Future<List<File>> _globDartFiles(LocalFileSystem fileSystem, String normalizedPath) async {
    final posixPath = normalizedPath.replaceAll('\\', '/');
    final dartGlob = Glob('$posixPath/**/*.dart', recursive: true);
    if (config.verbose) print('Glob pattern: ${dartGlob.pattern}');
    return dartGlob
        .listSync(followLinks: true)
        .whereType<File>()
        .where((entity) => entity.path.endsWith('.dart'))
        .toList();
  }

  List<File> _filterExcludedFiles(List<File> files) {
    return files.where((file) {
      final relativePath = path.relative(file.path, from: config.projectPath);
      if (config.excludeDirs.any((dir) => relativePath.startsWith('$dir${path.separator}'))) {
        if (config.verbose) print('Excluded by dir: $relativePath');
        return false;
      }
      if (config.excludeFiles.any((fileName) => relativePath.endsWith(fileName))) {
        if (config.verbose) print('Excluded by file: $relativePath');
        return false;
      }
      if (config.verbose) print('Added to process: $relativePath');
      return true;
    }).toList();
  }

  Future<void> _processFilesInBatches(List<File> files) async {
    const batchSize = 10;
    for (var i = 0; i < files.length; i += batchSize) {
      final batch = files.sublist(i, (i + batchSize).clamp(0, files.length));
      await Future.wait(batch.map(_checkFile));
      if (config.verbose) print('Processed ${i + batch.length} of ${files.length} files');
    }
  }

  Future<void> _checkFile(File file) async {
    try {
      final content = await file.readAsString();
      final relativePath = path.relative(file.path, from: config.projectPath);
      final parseResult = parseString(content: content);
      final visitor =
          StringLiteralVisitor(parseResult.lineInfo, verbose: config.verbose); // Pass verbose flag

      if (config.verbose) print('Parsing $relativePath');
      parseResult.unit.visitChildren(visitor);

      final lines = content.split('\n');
      for (final literal in visitor.literals) {
        if (_shouldProcessLiteral(literal, lines, relativePath)) {
          _results.add(NonLocalizedString(
            filePath: relativePath,
            lineNumber: literal.lineNumber,
            content: literal.content,
            context: _getContext(lines, literal.lineNumber),
          ));
        }
      }
    } catch (e) {
      if (config.verbose) print('Error processing ${file.path}: $e');
    }
  }

  bool _shouldProcessLiteral(StringLiteralInfo literal, List<String> lines, String filePath) {
    if (stringFilter.shouldSkip(literal.content) || literal.content.trim().isEmpty) {
      if (config.verbose)
        print('Skipped (filter or empty): "${literal.content}" in $filePath:${literal.lineNumber}');
      return false;
    }

    final contextLines = _getContext(lines, literal.lineNumber);
    if (!_isUiRelated(literal, contextLines)) {
      if (config.verbose)
        print('Skipped (non-UI): "${literal.content}" in $filePath:${literal.lineNumber}');
      return false;
    }

    final line = lines[literal.lineNumber - 1];
    if (stringFilter.isLocalized(line, literal.content, keysFinder.localizedKeys)) {
      if (config.verbose)
        print('Skipped (localized): "${literal.content}" in $filePath:${literal.lineNumber}');
      return false;
    }

    return true;
  }

  bool _isUiRelated(StringLiteralInfo literal, List<String> contextLines) {
    const standardUiPatterns = [
      'Text(',
      'RichText(',
      'TextFormField(',
      'validator:',
      'SnackBar(',
      'AlertDialog(',
      'Dialog(',
      'Toast(',
      'Notification(',
      'labelText:',
      'hintText:',
      'helperText:',
      'errorText:',
      'prefixText:',
      'suffixText:',
      'ElevatedButton(',
      'TextButton(',
      'OutlinedButton(',
      'FloatingActionButton(',
      'content:',
      'AppBar(',
      'BottomNavigationBar(',
      'Drawer(',
      'TabBar(',
      'title:',
      'Tooltip(',
      'Chip(',
      'Card(',
      'ListTile(',
      'placeholder:',
      'label:',
      'message:',
      'subtitle:'
    ];

    return contextLines.any((line) =>
            standardUiPatterns.any((pattern) => line.contains(pattern)) ||
            config.customUiPatterns.any((pattern) => line.contains(pattern))) ||
        (literal.parentNode != null &&
            (literal.parentNode.contains('validator:') ||
                literal.parentNode.contains('TextFormField') ||
                literal.parentNode.contains('label:') ||
                literal.parentNode.contains('errorMessage:') ||
                literal.parentNode.contains('hint:') ||
                literal.parentNode.contains('validationMessage:') ||
                literal.parentNode.contains('InstanceCreationExpression') ||
                config.customUiPatterns.any((pattern) => literal.parentNode.contains(pattern))));
  }

  List<String> _getContext(List<String> lines, int lineNumber) {
    final start = (lineNumber - 2).clamp(0, lines.length - 1);
    final end = (lineNumber + 1).clamp(0, lines.length - 1);
    return lines.sublist(start, end + 1);
  }

  void _logConfig() {
    print('Project path: ${config.projectPath}');
    print('Scan paths: ${config.scanPaths}');
    print('Excluded dirs: ${config.excludeDirs}');
    print('Excluded files: ${config.excludeFiles}');
    print('Custom UI patterns: ${config.customUiPatterns}');
  }

  void _logFiles(List<File> files) {
    print('Found ${files.length} Dart files to scan');
    final sampleSize = files.length > 5 ? 5 : files.length;
    print('Sample files:');
    for (var i = 0; i < sampleSize; i++) {
      print('  - ${files[i].path}');
    }
    if (files.length > sampleSize) {
      print('  ... and ${files.length - sampleSize} more');
    }
  }

  void modifyFilesWithLocalizationKeys() {
    final enJsonPath = path.join(config.projectPath, 'i18n', 'en.json');
    final translationUtilPath =
        path.join(config.projectPath, 'lib', 'legacy', 'translation_util.dart');

    // Load existing en.json
    final enJsonFile = File(enJsonPath);
    final enJson = enJsonFile.existsSync()
        ? json.decode(enJsonFile.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};

    // Load existing TranslationLabel class
    final translationUtilFile = File(translationUtilPath);
    final translationUtilContent = translationUtilFile.readAsStringSync();
    final translationLabelRegex = RegExp(r"static const (\w+) = '([^']+)';");
    final existingKeys = {
      for (final match in translationLabelRegex.allMatches(translationUtilContent))
        match.group(2): match.group(1)
    };

    for (final result in _results) {
      final file = File(path.join(config.projectPath, result.filePath));
      if (!file.existsSync()) continue;

      final lines = file.readAsLinesSync();
      final lineIndex = result.lineNumber - 1;

      if (lineIndex >= 0 && lineIndex < lines.length) {
        final originalLine = lines[lineIndex];
        final localizedKey = _generateLocalizationKey(result.content);

        // Add to en.json if not already present
        if (!enJson.containsKey(localizedKey)) {
          enJson[localizedKey] = result.content;
        }

        // Add to TranslationLabel if not already present
        if (!existingKeys.containsKey(localizedKey)) {
          final newConst = "  static const $localizedKey = '$localizedKey';\n";
          final insertIndex = translationUtilContent.lastIndexOf('}');
          translationUtilFile.writeAsStringSync(
            translationUtilContent.substring(0, insertIndex) +
                newConst +
                translationUtilContent.substring(insertIndex),
          );
          existingKeys[localizedKey] = localizedKey;
        }

        // Replace in Dart file
        final replacement = originalLine.replaceFirst(
          result.content,
          'translate(TranslationLabel.$localizedKey, context)',
        );
        lines[lineIndex] = replacement;

        if (config.verbose) {
          print('Modified ${result.filePath}:${result.lineNumber}');
          print('  Original: $originalLine');
          print('  Modified: $replacement');
        }
      }

      file.writeAsStringSync(lines.join('\n'));
    }

    // Save updated en.json
    enJsonFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(enJson));
  }

  String _generateLocalizationKey(String content) {
    return content
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .map((word) => word.toLowerCase())
        .join('_');
  }
}

class ReportGenerator {
  static String generate(List<NonLocalizedString> results) {
    final buffer = StringBuffer();
    buffer.writeln('Found ${results.length} non-localized strings:\n');
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.filePath}:${result.lineNumber} - "${result.content}"');
      buffer.writeln('Context:');
      final startLine = result.lineNumber - 2;
      for (var j = 0; j < result.context.length; j++) {
        final lineNum = startLine + j + 1;
        final indicator = result.context[j].contains(result.content) ? '>' : ' ';
        buffer.writeln('$indicator $lineNum: ${result.context[j]}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
