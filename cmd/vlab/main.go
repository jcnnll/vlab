package main

import (
	"errors"
	"fmt"
	"os"

	"github.com/jcnnll/vlab/internal/lima"
	"gopkg.in/yaml.v3"
)

// Version is populated at build time via -ldflags
var Version = "dev"

// VM list (from vlab.yaml)
var vms []string

func main() {
	// Load VM list at startup
	if err := loadVMs(); err != nil {
		// Only print a warning here: StartVMs / StopVMs will error if called
		fmt.Fprintf(os.Stderr, "Warning: %v\n", err)
	}

	if err := run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// loadVMs reads vlab.yaml and populates the package-level vms variable
func loadVMs() error {
	file, err := os.Open("vlab.yaml")
	if os.IsNotExist(err) {
		vms = nil
		return nil
	} else if err != nil {
		return err
	}
	defer file.Close()

	var cfg struct {
		VMs []string `yaml:"vms"`
	}

	if err := yaml.NewDecoder(file).Decode(&cfg); err != nil {
		return fmt.Errorf("failed to parse vlab.yaml: %w", err)
	}

	vms = cfg.VMs
	return nil
}

func run(args []string) error {
	usage := fmt.Sprintf("vlab %s usage: vlab [status|up|down|version]", Version)

	if len(args) < 2 {
		fmt.Println(usage)
		return nil
	}

	cmd := args[1]

	valid := map[string]struct{}{
		"status":  {},
		"up":      {},
		"down":    {},
		"version": {},
	}

	if _, ok := valid[cmd]; !ok {
		return fmt.Errorf("unknown command %q\n%s", cmd, usage)
	}

	switch cmd {
	case "version":
		fmt.Println(Version)
	case "status":
		return lima.StatusVMs()

	case "up":
		if len(vms) == 0 {
			return errors.New("no VMs provided: check vlab.yaml exists")
		}
		return lima.StartVMs(vms)

	case "down":
		if len(vms) == 0 {
			return errors.New("no VMs provided: check vlab.yaml exists")
		}
		return lima.StopVMs(vms)

	}

	return nil
}
