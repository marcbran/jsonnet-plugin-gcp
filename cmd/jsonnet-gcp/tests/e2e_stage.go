//go:build e2e

package tests

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	gcppkg "github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/pkg/jsonnetgcp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type Stage struct {
	t *testing.T

	facade   gcppkg.Facade
	tempDir  string
	codexLog string

	input      gcppkg.InferInput
	serviceDir string

	lastOutput         gcppkg.InferOutput
	lastGenerateOutput gcppkg.GenerateOutput
	lastErr            string
}

func scenario(t *testing.T) (*Stage, *Stage, *Stage) {
	tempDir := t.TempDir()
	codexLog := filepath.Join(tempDir, "codex.log")
	facade, err := NewCLIFacade(codexLog)
	require.NoError(t, err)
	s := &Stage{
		t:        t,
		facade:   facade,
		tempDir:  tempDir,
		codexLog: codexLog,
		input: gcppkg.InferInput{
			WorkDir: filepath.Join(tempDir, "work"),
		},
	}
	return s, s, s
}

func (s *Stage) and() *Stage {
	return s
}

func (s *Stage) the_service(service string) *Stage {
	s.input.Service = service
	s.input.Resources = filepath.Join(repoRoot(), "services", service, "inference", "resources.json")
	return s
}

func (s *Stage) a_cached_result(method string, result string) *Stage {
	path := filepath.Join(s.input.WorkDir, "columns-inference", "results", method+".json")
	err := os.MkdirAll(filepath.Dir(path), 0755)
	require.NoError(s.t, err)
	err = os.WriteFile(path, []byte(result), 0644)
	require.NoError(s.t, err)
	return s
}

func (s *Stage) the_columns_are_inferred() *Stage {
	out, err := s.facade.InferColumns(context.Background(), s.input)
	s.lastOutput = out
	s.lastErr = ""
	if err != nil {
		s.lastErr = err.Error()
	}
	return s
}

func (s *Stage) there_is_no_error() *Stage {
	require.Empty(s.t, s.lastErr)
	return s
}

func (s *Stage) the_error_mentions(text string) *Stage {
	assert.Contains(s.t, s.lastErr, text)
	return s
}

func (s *Stage) the_output_is(expected string) *Stage {
	raw, err := os.ReadFile(s.lastOutput.Out)
	require.NoError(s.t, err)
	assert.JSONEq(s.t, expected, string(raw))
	return s
}

func (s *Stage) codex_was_called_for(methods ...string) *Stage {
	assert.ElementsMatch(s.t, methods, s.codexCalls())
	return s
}

func (s *Stage) codexCalls() []string {
	raw, err := os.ReadFile(s.codexLog)
	if os.IsNotExist(err) {
		return nil
	}
	require.NoError(s.t, err)
	return strings.Fields(string(raw))
}

func testdataRoot() string {
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "testdata")
}

func repoRoot() string {
	return filepath.Join(testdataRoot(), "..", "..", "..", "..")
}
