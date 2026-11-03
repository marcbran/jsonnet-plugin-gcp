//go:build e2e

package tests

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	gcppkg "github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/pkg/jsonnetgcp"
)

type CLIFacade struct {
	binaryPath string
	codexLog   string
}

func NewCLIFacade(codexLog string) (gcppkg.Facade, error) {
	binaryPath := os.Getenv("JSONNET_GCP_BINARY")
	if binaryPath == "" {
		return nil, fmt.Errorf("JSONNET_GCP_BINARY is required")
	}
	_, err := os.Stat(binaryPath)
	if err != nil {
		return nil, fmt.Errorf("unable to access JSONNET_GCP_BINARY %q: %w", binaryPath, err)
	}
	return &CLIFacade{binaryPath: binaryPath, codexLog: codexLog}, nil
}

func (f *CLIFacade) Generate(ctx context.Context, in gcppkg.GenerateInput) (gcppkg.GenerateOutput, error) {
	args := []string{"gen", in.Service}
	if in.Inputs != "" {
		args = append(args, "--inputs", in.Inputs)
	}
	if in.Out != "" {
		args = append(args, "--out", in.Out)
	}
	stdout, err := f.run(ctx, args)
	if err != nil {
		return gcppkg.GenerateOutput{}, err
	}
	return gcppkg.GenerateOutput{Dir: in.Out, Files: strings.Fields(stdout)}, nil
}

func (f *CLIFacade) InferColumns(ctx context.Context, in gcppkg.InferInput) (gcppkg.InferOutput, error) {
	args := []string{"columns", "infer", in.Service, "-q"}
	if in.Out != "" {
		args = append(args, "--out", in.Out)
	}
	if in.WorkDir != "" {
		args = append(args, "--workdir", in.WorkDir)
	}
	if in.Resources != "" {
		args = append(args, "--resources", in.Resources)
	}
	if in.Model != "" {
		args = append(args, "--model", in.Model)
	}
	if in.Limit > 0 {
		args = append(args, "--limit", fmt.Sprintf("%d", in.Limit))
	}
	if in.Force {
		args = append(args, "--force")
	}
	stdout, err := f.run(ctx, args)
	if err != nil {
		return gcppkg.InferOutput{}, err
	}
	return gcppkg.InferOutput{Out: strings.TrimSpace(stdout), WorkDir: in.WorkDir}, nil
}

func (f *CLIFacade) run(ctx context.Context, args []string) (string, error) {
	cmd := exec.CommandContext(ctx, f.binaryPath, args...)
	cmd.Env = append(os.Environ(),
		"PATH="+filepath.Join(testdataRoot(), "bin")+string(os.PathListSeparator)+os.Getenv("PATH"),
		"FAKE_CODEX_LOG="+f.codexLog,
	)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		if stderr.String() != "" {
			return "", errors.New(stderr.String())
		}
		return "", err
	}
	return stdout.String(), nil
}
