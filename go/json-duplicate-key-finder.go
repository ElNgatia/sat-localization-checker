package main
import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
)

func  main() {
	inputFile := flag.String("input", "translations.json", "Path to the input JSON file")
	outputFile := flag.String("output", "cleaned_translations.json", "Path to the cleaned JSON output file")
	removedFile := flag.String("removed", "removed_duplicates.json", "Path to the removed duplicates file")
	flag.Parse()

	rawData, err := os.ReadFile(*inputFile)
	if err != nil {
		fmt.Println("❌ Error reading input file:", err)
		os.Exit(1)
	}

	decoder := json.NewDecoder(bytes.NewReader(rawData))
	var buffer bytes.Buffer
	encoder := json.NewEncoder(&buffer)
	encoder.SetIndent("", "  ")

	seenKeys := make(map[string]bool)
	removedDuplicates := make(map[string]interface{})

	// Start the object
	t, err := decoder.Token()
	if err != nil || t != json.Delim('{') {
		fmt.Println("❌ Expected JSON object at the top level")
		os.Exit(1)
	}
	buffer.WriteString("{\n")

	first := true
	for decoder.More() {
		// Read key
		t, err := decoder.Token()
		if err != nil {
			fmt.Println("❌ Error reading key:", err)
			os.Exit(1)
		}
		key := t.(string)

		// Read value
		var raw json.RawMessage
		if err := decoder.Decode(&raw); err != nil {
			fmt.Println("❌ Error reading value:", err)
			os.Exit(1)
		}

		if seenKeys[key] {
			// Store removed duplicates
			var value interface{}
			json.Unmarshal(raw, &value)
			removedDuplicates[key] = value
			continue
		}

		seenKeys[key] = true

		// Write to output buffer
		if !first {
			buffer.WriteString(",\n")
		}
		first = false

		buffer.WriteString(fmt.Sprintf("  %q: %s", key, string(raw)))
	}

	buffer.WriteString("\n}\n")

	// Write cleaned output
	if err := os.WriteFile(*outputFile, buffer.Bytes(), 0644); err != nil {
		fmt.Println("❌ Error writing cleaned output:", err)
		os.Exit(1)
	}

	// Write removed duplicates
	writeJSON(*removedFile, removedDuplicates)

	// Summary
	fmt.Println("✅ Duplicate keys cleanup complete!")
	fmt.Printf("✨ Unique keys kept: %d\n", len(seenKeys))
	fmt.Printf("🗑️ Duplicate keys removed: %d\n", len(removedDuplicates))
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
