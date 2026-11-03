//go:build e2e

package tests

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const evaluationTimeout = 30 * time.Second

type Stage struct {
	t *testing.T

	facade       Facade
	project      string
	otherProject string

	LastOutput string
	LastError  string
}

func scenario(t *testing.T) (*Stage, *Stage, *Stage) {
	project := newFlociProject()
	otherProject := newFlociProject()
	s := &Stage{
		t: t,
		facade: NewE2EFacade(flociEndpoint, map[string]string{
			"ctx.libsonnet":       fmt.Sprintf(`{ project: '%s' }`, project),
			"other-ctx.libsonnet": fmt.Sprintf(`{ project: '%s' }`, otherProject),
		}),
		project:      project,
		otherProject: otherProject,
	}
	t.Cleanup(s.close)
	return s, s, s
}

func (s *Stage) close() {
	_ = s.facade.Close()
}

func (s *Stage) and() *Stage {
	return s
}

func (s *Stage) the_jsonnet_is_evaluated(snippet string) *Stage {
	ctx, cancel := context.WithTimeout(context.Background(), evaluationTimeout)
	defer cancel()
	out, err := s.facade.Evaluate(ctx, snippet)
	s.LastOutput = out
	s.LastError = ""
	if err != nil {
		s.LastError = err.Error()
	}
	return s
}

func (s *Stage) there_is_no_error() *Stage {
	require.Empty(s.t, s.LastError)
	return s
}

func (s *Stage) the_output_is(expected string) *Stage {
	assert.JSONEq(s.t, expected, s.LastOutput)
	return s
}
