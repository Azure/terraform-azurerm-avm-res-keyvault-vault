package e2e

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

func TestE2E(t *testing.T) {
	ds, err := os.ReadDir(filepath.Join(rootDir, examplesDir))
	if err != nil {
		t.Fatal(err.Error())
	}
	for _, d := range ds {
		if !d.IsDir() {
			continue
		}
		testdir := filepath.Join(examplesDir, d.Name())
		fmt.Printf("Running %s\n", testdir)
		test, err := setuptest.Dirs(rootDir, testdir).WithVars(nil).InitPlanShow(t)
		if err != nil {
			t.Fatal(err.Error())
		}
		defer test.Cleanup()
		test.ApplyIdempotent().ErrorIsNil(t)
		test.Destroy().ErrorIsNil(t)
	}
}
