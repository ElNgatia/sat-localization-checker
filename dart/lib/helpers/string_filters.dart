import 'package:loc_checker/config.dart';

class StringFilter {
  final LocalizationCheckerConfig config;
  static const _localizationPatterns = [
    r'AppLocalizations\s*\.\s*of\s*\(\s*[^)]+\s*\)\s*\.\s*[a-zA-Z0-9_]+',
    r'AppLocalizations\s*\.\s*[a-zA-Z0-9_]+',
    r'\.tr\s*(?=\()',
    r'\.trParams\s*(?=\()',
    r'"[a-zA-Z0-9_]+"\.tr\b',
    r'LocaleKeys\s*\.\s*[a-zA-Z0-9_]+\s*\.\s*tr\s*\(\s*\)',
    r'tr\s*\(\s*[a-zA-Z0-9_]+\)',
    r'Intl\s*\.\s*message\s*\(\s*.*\s*\)',
    r'Intl\s*\.\s*plural\s*\(\s*[0-9]+.*\s*\)',
    r'Intl\s*\.\s*select\s*\(\s*[^,]+,\s*\{.*\}\s*\)',
    r'I18n\s*\.\s*of\s*\(\s*[^)]+\s*\)\s*\.\s*[a-zA-Z0-9_]+',
    r'S\s*\.\s*of\s*\(\s*[^)]+\s*\)\s*\.\s*[a-zA-Z0-9_]+',
    r'S\s*\.\s*current\s*\.\s*[a-zA-Z0-9_]+',
    r'context\s*\.\s*l10n\s*\.\s*[a-zA-Z0-9_]+',
    r'translate\s*\(\s*[a-zA-Z0-9_]+\s*\)',
  ];

  StringFilter(this.config);

  bool shouldSkip(String content) {
  if (content.isEmpty || content.trim().isEmpty || content.length == 1) return true;
  if (RegExp(r'^[0-9.,]+$').hasMatch(content)) return true;
  if (RegExp(r'^[!@#$%^&*()_\-+=<>?/|\\{}\[\]]+$').hasMatch(content)) return true;
  if (content.startsWith('http://') || content.startsWith('https://')) return true;
  if (content.startsWith('assets/') || content.contains('.dart')) return true;

  // Skip interpolated strings with translate function
  if (content.contains(r'${') && content.contains('translate(')) return true;

  // Skip strings using .trWith( for params
  if (content.contains('.trWith(')) return true;

  // Skip strings using .tr() with no params
  if (content.contains('.tr(')) return true;


  // Keep interpolated strings with text (but without translate)
  if (content.contains(r'${') && content.contains('}') && content.length > 5) return false;

  // Keep potential UI text
  if (content.length > 3 && content.contains(' ') && !content.contains('://')) return false;

  return true;
  }

  bool isLocalized(String line, String content, Set<String> localizedKeys) {
    if (_localizationPatterns
        .any((pattern) => RegExp(pattern).hasMatch(line))) {
      if (config.verbose) print('Matched localization pattern in: $line');
      return true;
    }
    if (localizedKeys.contains(content.trim())) {
      if (config.verbose) print('Matched localized key: $content');
      return true;
    }
    if (!config.includeComments &&
        (line.trim().startsWith('//') ||
            line.trim().startsWith('/*') ||
            line.trim().endsWith('*/'))) {
      return true;
    }
    return false;
  }
}
