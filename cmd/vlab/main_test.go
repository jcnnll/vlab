package main

import (
	"os"
	"testing"
)

type MockVMProvider struct{}

func (m MockVMProvider) StatusVMs() error {
	return nil
}

func (m MockVMProvider) StartVMs(vms []string) error {
	return nil
}

func (m MockVMProvider) StopVMs(vms []string) error {
	return nil
}

func TestCommandRouting(t *testing.T) {
	mock := MockVMProvider{}

	tests := []struct {
		name    string
		args    []string
		wantErr bool
	}{
		{"No args", []string{"vlab"}, false},
		{"Version command", []string{"vlab", "version"}, false},
		{"Status command", []string{"vlab", "status"}, false},
		{"Up command", []string{"vlab", "up"}, true},
		{"Down command", []string{"vlab", "down"}, true},
		{"Unknown command", []string{"vlab", "invalid"}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := run(tt.args, mock)
			if (err != nil) != tt.wantErr {
				t.Errorf("run() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestLoadVMs(t *testing.T) {
	tests := []struct {
		name    string
		content string // contents of vlab.yaml; empty string = file missing
		wantErr bool
		wantVMs []string
	}{
		{"missing file", "", false, []string{}},
		{"malformed yaml", "vms: [unclosed", true, nil},
		{"empty yaml", "vms:\n", false, []string{}},
		{"valid yaml", "vms:\n  - dns\n  - db\n", false, []string{"dns", "db"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tmpDir := t.TempDir()
			os.Chdir(tmpDir)

			if tt.content != "" {
				if err := os.WriteFile("vlab.yaml", []byte(tt.content), 0o644); err != nil {
					t.Fatal(err)
				}
			}

			// Reset global vms slice
			vms = nil

			err := loadVMs()
			if (err != nil) != tt.wantErr {
				t.Fatalf("loadVMs() error = %v, wantErr %v", err, tt.wantErr)
			}

			if len(vms) != len(tt.wantVMs) {
				t.Fatalf("vms = %v, want %v", vms, tt.wantVMs)
			}

			for i := range vms {
				if vms[i] != tt.wantVMs[i] {
					t.Fatalf("vms[%d] = %q, want %q", i, vms[i], tt.wantVMs[i])
				}
			}
		})
	}
}
