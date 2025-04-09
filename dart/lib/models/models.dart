class NonLocalizedString {
  final String filePath;
  final int lineNumber;
  final String content;
  final List<String> context;

  NonLocalizedString({
    this.filePath,
    this.lineNumber,
    this.content,
    this.context,
  });

  @override
  String toString() =>
      '$filePath:$lineNumber - "$content"\nContext:\n  ${context.join("\n  ")}';
}

class StringLiteralInfo {
  final String content;
  final int lineNumber;
  final bool isInterpolated;
  final String parentNode;

  StringLiteralInfo({
    this.content,
    this.lineNumber,
    this.isInterpolated,
    this.parentNode,
  });
}
