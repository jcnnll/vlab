// Package lima provides helpers for managing Lima virtual machines
// via the limactl CLI.
//
// It includes functions to start, stop, and list VMs in a simple,
// programmatic way suitable for CLI tools like vlab.
package lima

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
)

// StartVMs iterates through a list of VM names and starts them via limactl
func StartVMs(vms []string) error {
	if len(vms) == 0 {
		return errors.New("no VMs provided")
	}

	for _, vm := range vms {
		cmd := exec.Command("limactl", "start", vm)
		// Stream output live
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to start VM %s: %w", vm, err)
		}
	}

	cmd := exec.Command("limactl", "list")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to list VMs: %w", err)
	}

	return nil
}

// StopVMs reverse iterates through a list of VM names and stops them via limactl
func StopVMs(vms []string) error {
	if len(vms) == 0 {
		return errors.New("no VMs provided")
	}

	for i := len(vms) - 1; i >= 0; i-- {
		vm := vms[i]

		cmd := exec.Command("limactl", "stop", vm)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin

		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to stop VM %s: %w", vm, err)
		}
	}

	return nil
}

// StatusVMs uses limactl to list the status of the VMs
func StatusVMs() error {
	cmd := exec.Command("limactl", "list")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}
