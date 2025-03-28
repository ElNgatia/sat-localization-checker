# loc_checker

A Dart command-line tool to detect non-localized strings in Flutter projects and generate ARB files for localization. Designed for developers who want to ensure their Flutter apps are fully localized, `loc_checker` scans Dart files, identifies UI-related strings that need translation, and outputs them into a structured `en.arb` file with camelCase keys and named placeholders.

## 🚀 Features

- **🔍 String Detection**: Identifies non-localized strings in Dart files, focusing on UI-related contexts (e.g., `Text`, `TextFormField`).
- **📂 ARB Generation**: Creates an `en.arb` file with camelCase keys (e.g., `myAccount`) and deduplicated values.
- **🔢 Placeholder Support**: Converts Dart string interpolations (e.g., `$variable`) into named placeholders (e.g., `{param0}`) with proper ARB metadata.
- **⚙️ Custom UI Patterns**: Allows users to specify custom UI components (e.g., `CustomTextField`) to include in the scan.
- **📜 Verbose Logging**: Provides detailed output for debugging when enabled.
- **🔧 Scalable Design**: Modular code structure for easy extension and maintenance.

## 📥 Installation

### As a dev dependency:

```sh
dart pub add --dev loc_checker
```

### Install globally:

```sh
dart pub global activate loc_checker
```

## 🚀 Usage

Run `loc_checker` on your Flutter project to scan for non-localized strings and optionally generate an ARB file.

### 🔍 Basic Command: Scan a project and output a report

```sh
dart run loc_checker /path/to/your/flutter/project -o report.txt
```

### 📂 Generate ARB File: Scan and create an `en.arb` file

```sh
dart run loc_checker --generate-arb --arb-output /path/to/your/flutter/project/lib/l10n /path/to/your/flutter/project -o report.txt
```

### 🛠️ With Verbose Logging: Enable detailed logs

```sh
dart run loc_checker --verbose --generate-arb /path/to/your/flutter/project -o report.txt
```

### 🎯 Custom UI Components: Include custom UI widgets in the scan

```sh
dart run loc_checker --custom-ui "CustomTextField,validator" /path/to/your/flutter/project -o report.txt
```

### 🏆 Full Example: Scan, generate ARB, and use all options

```sh
dart run loc_checker --verbose --generate-arb --custom-ui "CustomTextField,validator" --scan-paths "/path/to/lib,/path/to/src" /path/to/your/flutter/project -o report.txt --arb-output /path/to/your/flutter/project/lib/l10n
```

## 📌 Command-Line Options

| Option           | Description                                   | Default                |
|-----------------|-----------------------------------------------|------------------------|
| `--verbose, -v`  | Enable detailed logging                       | `false`                |
| `--generate-arb` | Generate an `en.arb` file                     | `false`                |
| `--arb-output`   | Directory to save the `en.arb` file           | Project root           |
| `--scan-paths`   | Comma-separated paths to scan                 | `lib/` in project root |
| `--custom-ui`    | Comma-separated custom UI patterns to include | `None`                 |
| `-o, --output`   | Path for the report file                      | `report.txt`           |
| `[project_path]` | Root directory of the Flutter project         | Current directory      |

## 📜 Output

### 📋 Report File (`report.txt`)

A text file listing non-localized strings with file paths, line numbers, and context:

```
Found 2 non-localized strings:

1. lib/widgets/custom.dart:1 - "Username"
   Context:
     1: CustomTextField(label: 'Username')
     2: TextFormField(validator: (v) => v.isEmpty ? 'Required field' : null)

2. lib/widgets/custom.dart:2 - "Required field"
   Context:
     1: CustomTextField(label: 'Username')
     2: TextFormField(validator: (v) => v.isEmpty ? 'Required field' : null)
```

### 📂 ARB File (`en.arb`)

A localization file with camelCase keys and named placeholders:

```json
{
  "username": "Username",
  "requiredField": "Required field",
  "uploadFailedWithStatusMessage": "Upload failed with status: {param0}, message: {param1}",
  "@uploadFailedWithStatusMessage": {
    "description": "String with placeholders from lib/network.dart:10",
    "placeholders": {
      "param0": {},
      "param1": {}
    }
  }
}
```

## 🔍 How It Works

1. **Scanning**: Analyzes Dart files in the specified paths (default: `lib/`), excluding common non-source directories (`build`, `.dart_tool`).
2. **Detection**: Uses AST parsing to find string literals in UI-related contexts, skipping localized strings (`AppLocalizations.of(context).key`).
3. **Filtering**: Ignores non-UI strings, empty strings, URLs, and other non-translatable content.
4. **ARB Generation**: Converts detected strings into a deduplicated `en.arb` file with camelCase keys and proper placeholder metadata.

## 📌 Contribution

Feel free to submit issues, feature requests, or pull requests to improve `loc_checker`.

## 📜 License

This project is licensed under the MIT License.

---

**Made with ❤️ for Flutter developers!** 🚀
