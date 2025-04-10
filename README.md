# SAT Localization Checker

## Overview

Localization Checker (`loc_checker`) is a command-line tool for Flutter projects that helps identify non-localized strings in your codebase and automates the generation of localization files. It's designed to be run locally in your project on both Windows and Linux systems.

## Project Structure

This project is organized as a monorepo with two main components:

- **Dart Tool**: Identifies non-localized strings and generates ARB files
- **Go Tool**: Checks for duplicates in generated JSON/ARB files

```
sat-localization-checker/
├─ dart/               # Main localization checker tool
│  ├─ bin/
│  │  └─ loc_checker.dart
├─ go/                 # JSON duplicate checker tool
│  └─ duplicate_checker.go
├─ scripts/            # Integration scripts
│  ├─ check_localization.sh
│  └─ check_localization.bat
```

## Features

- **String Detection**: Identifies non-localized strings in Dart files that should be translated
- **ARB Generation**: Creates `en.arb` files with properly formatted keys and placeholders
- **Code Modification**: Can automatically update your code to use localization keys
- **Customizable Scanning**: Configure which paths to scan and which UI patterns to look for
- **Detailed Reporting**: Generates reports showing where non-localized strings appear
- **Duplicate Detection**: Identifies duplicate keys and values in generated ARB files

## Installation

Since this tool is intended for local use rather than publication to pub.dev, you should clone or download the repository directly to your machine.

### Setup

1. Clone the repository:
   ```
   git clone https://github.com/ElNgatia/sat-localization-checker.git
   ```

2. Get Dart dependencies:
   ```
   cd sat-localization-checker/dart
   dart pub get
   ```

3. Build Go tool:
   ```
   # For Linux
   cd ../go
   go build -o ../bin/duplicate_checker

   # For Windows
   cd ..\go
   go build -o ..\bin\duplicate_checker.exe
   ```

## Using the Dart Localization Checker

### Basic Command

Scan a project and generate a report:

```
cd dart
dart run bin/loc_checker.dart path/to/solutech-sat -o report.txt
```

### Generate ARB File

Scan a project and generate both a report and an ARB file:

```
dart run bin/loc_checker.dart path/to/solutech-sat --generate-arb --arb-output lib/l10n -o report.txt
```

### Modify Files

Scan a project, generate a report, and modify files to use localization:

```
dart run bin/loc_checker.dart path/to/solutech-sat --modify-files -o report.txt
```

### With Custom UI Components

Include custom UI components in the scan:

```
dart run bin/loc_checker.dart path/to/solutech-sat --custom-ui "CustomTextField,CustomButton" -o report.txt
```

### With Verbose Logging

Enable detailed logging for debugging:

```
dart run bin/loc_checker.dart path/to/solutech-sat --verbose -o report.txt
```

## Using the Go Duplicate Checker

The Go tool checks for duplicate keys and values in your ARB/JSON files:

```
# Linux
./bin/duplicate_checker -input path/to/en.json -output cleaned.json -removed removed.json

# Windows
bin\duplicate_checker.exe -input path\to\en.json -output cleaned.json -removed removed.json
```

### Options

- `-input`: Path to the input JSON file (default: "en.json")
- `-output`: Path to write cleaned JSON file (default: "cleaned.json")
- `-removed`: Path to write removed duplicates (default: "removed.json")

## Running Both Tools Together

You can use the provided scripts to run both tools in sequence:

```
# Linux
./scripts/check_localization.sh path/to/solutech-sat --generate-arb

# Windows
scripts\check_localization.bat path\to\solutech-sat --generate-arb
```

## Command-Line Options for Dart Tool

| Option | Description | Default |
|--------|-------------|---------|
| `--verbose`, `-v` | Enable verbose logging | `false` |
| `--generate-arb` | Generate an ARB file | `false` |
| `--modify-files` | Update code to use localization keys | `true` |
| `--scan-paths` | Comma-separated list of paths to scan | lib |
| `--custom-ui` | Comma-separated list of custom UI patterns | `[]` |
| `--output`, `-o` | Path for the report file | `report.txt` |
| `--arb-output` | Directory to save the ARB file | Project root |
| `path/to/solutech-sat` | Root directory of the Flutter project | Current directory |

## Output Files

### Report File

The generated report lists all non-localized strings with their file paths, line numbers, and context:

```
Found 2 non-localized strings:

1. lib/widgets/custom.dart:25 - "Username"
Context:
 23: Widget build(BuildContext context) {
>24:   return TextField(
>25:     hintText: "Username",
 26:   );

2. lib/pages/login.dart:42 - "Please enter your password"
Context:
 40: validator: (value) {
>41:   if (value.isEmpty) {
>42:     return "Please enter your password";
 43:   }
```

### ARB File

The generated ARB file contains all identified strings with appropriate keys:

```json
{
  "username": "Username",
  "pleaseEnterYourPassword": "Please enter your password",
  "welcomeToAppName": "Welcome to {param0}",
  "@welcomeToAppName": {
    "description": "String with placeholders from lib/home.dart:15",
    "placeholders": {
      "param0": {}
    }
  }
}
```

### Duplicate Checker Output

The Go duplicate checker produces two files:
- `cleaned.json`: Original file with duplicates removed
- `removed.json`: Only the duplicate entries that were removed

## How It Works

1. **Scanning**: The Dart tool scans your Dart files using the Dart analyzer to build an AST.
2. **Detection**: It identifies string literals in UI contexts like `Text()` widgets, form validators, etc.
3. **Filtering**: Non-UI strings, URLs, empty strings, and already localized strings are filtered out.
4. **Reporting**: All non-localized strings are collected into a comprehensive report.
5. **ARB Generation**: When enabled, an ARB file is created with appropriate keys and placeholder metadata.
6. **Code Modification**: When enabled, source files are updated to use localization keys.
7. **Duplicate Checking**: The Go tool analyzes the generated ARB file to find and remove duplicates.

## Project Configuration

You can exclude specific directories from scanning by modifying the configuration in config.dart:

```dart
excludeDirs: const [
  'build',
  '.dart_tool',
  '.pub',
  '.git',
  'test',
  'bin'
]
```

## Troubleshooting

- **Missing dependencies**: Make sure to run `dart pub get` before using the tool.
- **Go build errors**: Ensure you have Go installed (`go version`) and that the build command executes successfully.
- **Path issues**: Use forward slashes (`/`) in paths even on Windows for best results.

## Limitations

- The tool assumes a standard Flutter project structure.
- It may not detect all possible ways of defining localized strings.
- Complex string interpolations might not be handled correctly.