package main

import "testing"

func TestVLabGreeting(t *testing.T) {
	expected := "hello vlab"

	if expected != "hello vlab" {
		t.Errorf("Expected %s, but got something else", expected)
	}
}
