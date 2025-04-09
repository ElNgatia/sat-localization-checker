import 'dart:convert';
import 'dart:io';

import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:loc_checker/config.dart';

class LocalizedKeysFinder {
  final LocalizationCheckerConfig config;
  final Set<String> _localizedKeys = {};

  LocalizedKeysFinder(this.config);

  Set<String> get localizedKeys => _localizedKeys;

  Future<void> findLocalizedKeys() async {
    final fileSystem = LocalFileSystem();
    await _findArbKeys(fileSystem);
    await _findJsonKeys(fileSystem);
    if (config.verbose) {
      print('Found ${_localizedKeys.length} localized keys');
    }
  }

  Future<void> _findArbKeys(LocalFileSystem fileSystem) async {
    final posixPath = config.projectPath.replaceAll('\\', '/');
    final arbGlob = Glob('$posixPath/**/*.arb', recursive: true);
    if (config.verbose) print('ARB pattern: ${arbGlob.pattern}');
    for (final entity in arbGlob.listSync()) {
      if (entity is File) {
        try {
          final content = await (entity).readAsString();
          final arbMap = json.decode(content) as Map<String, dynamic>;
          arbMap.keys
              .where((key) => !key.startsWith('@'))
              .forEach(_localizedKeys.add);
        } catch (e) {
          if (config.verbose) print('Error parsing ARB ${entity.path}: $e');
        }
      }
    }
  }

  Future<void> _findJsonKeys(LocalFileSystem fileSystem) async {
    final posixPath = config.projectPath.replaceAll('\\', '/');
    final globs = [
      Glob('$posixPath/**/i18n/*.json', recursive: true),
      Glob('$posixPath/**/translations/*.json', recursive: true),
    ];
    for (final glob in globs) {
      if (config.verbose) print('JSON pattern: ${glob.pattern}');
      for (final entity in glob.listSync()) {
        if (entity is File) {
          try {
            final content = await (entity).readAsString();
            final jsonMap = json.decode(content) as Map<String, dynamic>;
            _extractKeys(jsonMap, '');
          } catch (e) {
            if (config.verbose) print('Error parsing JSON ${entity.path}: $e');
          }
        }
      }
    }
  }

  void _extractKeys(Map<String, dynamic> json, String prefix) {
    json.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _extractKeys(value, fullKey);
      } else if (value is String) {
        _localizedKeys.add(fullKey);
        _localizedKeys.add(value);
      }
    });
  }
}
