package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
)

func main() {
	inputFile := flag.String("input", "translations.json", "Path to the input JSON file")
	outputFile := flag.String("output", "cleaned_translations.json", "Path to the cleaned JSON output file")
	removedFile := flag.String("removed", "removed_duplicates.json", "Path to the removed duplicates file")
	flag.Parse()

	// Read input JSON
	data, err := os.ReadFile(*inputFile)
	if err != nil {
		fmt.Println("❌ Error reading input file:", err)
		os.Exit(1)
	}

	// Parse JSON into map
	var translations map[string]string
	if err := json.Unmarshal(data, &translations); err != nil {
		fmt.Println("❌ Error parsing JSON:", err)
		os.Exit(1)
	}

	// Reverse map value -> []keys
	valueToKeys := make(map[string][]string)
	for key, value := range translations {
		valueToKeys[value] = append(valueToKeys[value], key)
	}

	// Prepare cleaned translations and removed duplicates
	cleanedTranslations := make(map[string]string)
	removedDuplicates := make(map[string]string)

	for value, keys := range valueToKeys {
		if len(keys) > 1 {
			// Keep the first key, remove others
			cleanedTranslations[keys[0]] = value
			for _, dupKey := range keys[1:] {
				removedDuplicates[dupKey] = value
			}
		} else {
			// Keep unique entries
			cleanedTranslations[keys[0]] = value
		}
	}

	// Write cleaned JSON
	writeJSON(*outputFile, cleanedTranslations)

	// Write removed duplicates JSON
	writeJSON(*removedFile, removedDuplicates)

	// Summary
	fmt.Println("✅ Cleanup complete!")
	fmt.Printf("✨ Unique entries kept: %d\n", len(cleanedTranslations))
	fmt.Printf("🗑️ Duplicates removed: %d\n", len(removedDuplicates))
	fmt.Println("📄 Cleaned output written to:", *outputFile)
	fmt.Println("📄 Removed duplicates written to:", *removedFile)
}

func writeJSON(filename string, data interface{}) {
	outputJSON, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		fmt.Println("❌ Error creating JSON for", filename, ":", err)
		os.Exit(1)
	}
	if err := os.WriteFile(filename, outputJSON, 0644); err != nil {
		fmt.Println("❌ Error writing file", filename, ":", err)
		os.Exit(1)
	}
}
