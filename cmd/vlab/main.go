package main

import (
	"fmt"
	"os"
)

// Version is populated at build time via -ldflags
var Version = "dev"

func main() {
	if err := run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) < 2 {
		fmt.Printf("vlab %s - Native macOS Virtualization\n", Version)
		fmt.Println("Usage: vlab [status|up|down|version]")
		return nil
	}

	cmd := args[1]

	switch cmd {
	case "version":
		fmt.Println(Version)
	case "status":
		fmt.Println("Checking vlab host status")
		// TODO: Call check

	case "up":
		fmt.Println("Starting vlab infrastructure")
		// TODO: Call up

	case "down":
		fmt.Println("Stopping vlab infrastructure")
		// TODO: Call down

	default:
		return fmt.Errorf("unknown command %s", cmd)
	}

	return nil
}
