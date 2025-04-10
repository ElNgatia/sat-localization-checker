#!/bin/bash
# Build for all platforms

echo "Building Go duplicate checker for all platforms..."

# Ensure we're in the go directory
cd "$(dirname "$0")"

# Ensure bin directory exists
mkdir -p ../bin

# Build for Linux
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -o ../bin/duplicate_checker json-duplicates-finder.go

# Build for Windows
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -o ../bin/duplicate_checker.exe json-duplicates-finder.go

# Build for macOS
echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -o ../bin/duplicate_checker_mac json-duplicates-finder.go

echo "Build complete!"