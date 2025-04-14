import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:loc_checker/models/models.dart';

class StringLiteralVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;
  final bool verbose; // Add verbose flag
  final List<StringLiteralInfo> literals = [];

  StringLiteralVisitor(this.lineInfo, {this.verbose = false});

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _addLiteral(node, false, node.value);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final parts = <String>[];
    var placeholderIndex = 0;
    var hasWords = false;
    var rawContent = '';

    for (final element in node.elements) {
      if (element is InterpolationString) {
        final text = element.value;
        rawContent += text;
        if (text.trim().isNotEmpty && RegExp(r'[a-zA-Z]{2,}').hasMatch(text)) {
          hasWords = true;
        }
        parts.add(text);
      } else if (element is InterpolationExpression) {
        parts.add('{param$placeholderIndex}');
        placeholderIndex++;
      }
    }

    final content = parts.join();

    // If there's no real word and the raw content is only punctuation/space, skip
    if (!hasWords) {
      if (verbose) {
        print('AST: Skipping "$content" (no real words)');
      }
      return;
    }

    _addLiteral(node, true, content);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    final content = node.strings.map((s) => s is SimpleStringLiteral ? s.value : '').join();

    // Skip if it's only punctuation or whitespace
    if (content.trim().isEmpty || !RegExp(r'[a-zA-Z]{2,}').hasMatch(content)) {
      if (verbose) {
        print('AST: Skipping adjacent strings "$content" (no real words)');
      }
      return;
    }

    if (content.isNotEmpty) {
      _addLiteral(node, false, content);
    }
  }

  void _addLiteral(AstNode node, bool isInterpolated, String content) {
    final lineNumber = lineInfo.getLocation(node.offset).lineNumber;
    String parentNode = _getParentNode(node);
    if (verbose) {
      print('AST: Found "$content" at line $lineNumber, parent: $parentNode');
    }
    literals.add(StringLiteralInfo(
      content: content,
      lineNumber: lineNumber,
      isInterpolated: isInterpolated,
      parentNode: parentNode,
    ));
  }

  String _getParentNode(AstNode node) {
    AstNode current = node.parent;
    while (current != null) {
      if (current is NamedExpression) {
        return '${current.name.label.name}: in ${current.parent.runtimeType}';
      } else if (current is InstanceCreationExpression) {
        return current.constructorName.toString();
      }
      current = current.parent;
    }
    return null;
  }
}
