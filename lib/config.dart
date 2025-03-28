import 'package:path/path.dart' as path;

class LocalizationCheckerConfig {
  final String projectPath;
  final List<String> scanPaths;
  final List<String> excludeDirs;
  final List<String> excludeFiles;
  final bool verbose;
  final bool includeComments;
  final List<String> customUiPatterns;

  LocalizationCheckerConfig({
     this.projectPath,
    List<String> scanPaths,
    this.excludeDirs = const [
      'build',
      '.dart_tool',
      '.pub',
      '.git',
      'test',
      'bin'
    ],
    this.excludeFiles = const [],
    this.verbose = false,
    this.includeComments = false,
    this.customUiPatterns = const [],
  }) : scanPaths = scanPaths ?? [path.join(projectPath, 'lib')];

  LocalizationCheckerConfig copyWith({
    List<String> scanPaths,
    List<String> customUiPatterns,
  }) =>
      LocalizationCheckerConfig(
        projectPath: projectPath,
        scanPaths: scanPaths ?? this.scanPaths,
        excludeDirs: excludeDirs,
        excludeFiles: excludeFiles,
        verbose: verbose,
        includeComments: includeComments,
        customUiPatterns: customUiPatterns ?? this.customUiPatterns,
      );
}
