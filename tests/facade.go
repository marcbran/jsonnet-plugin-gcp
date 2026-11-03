//go:build e2e

package tests

import (
	"bytes"
	"context"

	"github.com/marcbran/jpoet/pkg/jpoet"
	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
	"github.com/marcbran/jsonnet-plugin-gcp/services/compute"
	"github.com/marcbran/jsonnet-plugin-gcp/services/storage"
)

type Facade interface {
	Evaluate(ctx context.Context, snippet string) (string, error)
	Close() error
}

type JpoetFacade struct {
	plugin *jpoet.Plugin
	env    *jpoet.Environment
}

func NewE2EFacade(endpoint string, imports map[string]string) Facade {
	plugin := gcp.Plugin(
		gcp.WithServices(compute.Service, storage.Service),
		gcp.WithEndpointResolver(func(*gcp.Service) (string, error) {
			return endpoint, nil
		}),
		gcp.WithCredentialsByRequest(func(_ context.Context, ci gcp.CallInput) (gcp.Credentials, error) {
			return flociCredentials(ci.Project), nil
		}),
	)
	opts := []jpoet.EnvOption{
		jpoet.EnvWithPlugin(plugin),
		jpoet.EnvFileImport([]string{".."}),
	}
	for filename, content := range imports {
		opts = append(opts, jpoet.EnvStringImport(filename, content))
	}
	env := jpoet.Env(opts...)
	return &JpoetFacade{plugin: plugin, env: env}
}

func (f *JpoetFacade) Evaluate(ctx context.Context, snippet string) (string, error) {
	return runWithContext(ctx, func() (string, error) {
		var out bytes.Buffer
		err := f.env.Eval(
			jpoet.EvalSnippetInput("main.jsonnet", snippet),
			jpoet.EvalWriterOutput(&out),
		)
		return out.String(), err
	})
}

func (f *JpoetFacade) Close() error {
	return f.env.Close()
}

func runWithContext[T any](ctx context.Context, fn func() (T, error)) (T, error) {
	type result struct {
		value T
		err   error
	}
	done := make(chan result, 1)
	go func() {
		value, err := fn()
		done <- result{value, err}
	}()
	select {
	case r := <-done:
		return r.value, r.err
	case <-ctx.Done():
		var zero T
		return zero, ctx.Err()
	}
}
