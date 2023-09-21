package main

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/Azure/terratest-terraform-fluent/setuptest"
)

const (
	examplesDir = "examples"
	rootDir     = "../../"
)

func main() {
	// ...
	err := rune2e()
	if err != nil {
		fmt.Fprint(os.Stderr, err.Error())
		os.Exit(1)
	}
	os.Exit(0)
}

func rune2e() error {

	ds, err := os.ReadDir(filepath.Join(rootDir, examplesDir))
	if err != nil {
		return err
	}
	for _, d := range ds {
		if !d.IsDir() {
			continue
		}
		testdir := filepath.Join(examplesDir, d.Name())
		fmt.Printf("Running %s\n", testdir)
		fakeT := new(testing.T)
		test, err := setuptest.Dirs(rootDir, testdir).WithVars(nil).InitPlanShow(fakeT)
		if err != nil {
			return err
		}
		defer test.Cleanup()
		defer test.Destroy()
		err = test.ApplyIdempotent().AsError()
		if err != nil {
			return err
		}
	}
	return nil
}
