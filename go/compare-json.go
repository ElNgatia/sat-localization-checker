package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
)

func main() {
	file1Path := flag.String("file1", "file1.json", "Path to the reference JSON file")
	file2Path := flag.String("file2", "file2.json", "Path to the comparison JSON file")
	reportPath := flag.String("report", "report.json", "Path to the output report file")
	flag.Parse()

	// Read and parse JSON files
	file1Data := readJSONFile(*file1Path)
	file2Data := readJSONFile(*file2Path)

	// Find missing keys and their original values
	missingEntries := findMissingEntries(file1Data, file2Data)

	// Write report to JSON file
	writeReport(missingEntries, *reportPath)

	fmt.Println("✅ Report written to", *reportPath)
}

func readJSONFile(path string) map[string]interface{} {
	data, err := os.ReadFile(path)
	if err != nil {
		fmt.Println("❌ Error reading file:", path, ":", err)
		os.Exit(1)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(data, &result); err != nil {
		fmt.Println("❌ Error parsing JSON from file:", path, ":", err)
		os.Exit(1)
	}

	return result
}

func findMissingEntries(reference, comparison map[string]interface{}) map[string]string {
	missing := make(map[string]string)

	for key, value := range reference {
		if _, exists := comparison[key]; !exists {
			// Convert value to string for translation purposes
			missing[key] = fmt.Sprintf("%v", value)
		}
	}

	return missing
}

func writeReport(report map[string]string, path string) {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		fmt.Println("❌ Error marshaling report:", err)
		os.Exit(1)
	}

	if err := os.WriteFile(path, data, 0644); err != nil {
		fmt.Println("❌ Error writing report file:", err)
		os.Exit(1)
	}
}
