package main

import "testing"

func TestCommandRouting(t *testing.T) {
	tests := []struct {
		name    string
		args    []string
		wantErr bool
	}{
		{"No args", []string{"vlab"}, false},
		{"Version command", []string{"vlab", "version"}, false},
		{"Status command", []string{"vlab", "status"}, false},
		{"Up command", []string{"vlab", "up"}, false},
		{"Down command", []string{"vlab", "down"}, false},
		{"Unknown command", []string{"vlab", "invalid"}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := run(tt.args)
			if (err != nil) != tt.wantErr {
				t.Errorf("run() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
