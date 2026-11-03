package jsonnetgcp

import (
	"context"

	"github.com/marcbran/jpoet/pkg/jpoet"

	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/inference"
	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/jsonnetgcp/columns"
	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/jsonnetgcp/gen"
	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/jsonnetgcp/infer"
	gcppkg "github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/pkg/jsonnetgcp"
)

type facade struct {
	loader   inference.ModelLoader
	progress inference.Progress
	plugins  []*jpoet.Plugin
}

func NewFacade(loader inference.ModelLoader, progress inference.Progress, plugins ...*jpoet.Plugin) gcppkg.Facade {
	return &facade{loader: loader, progress: progress, plugins: plugins}
}

func (f *facade) Generate(ctx context.Context, in gcppkg.GenerateInput) (gcppkg.GenerateOutput, error) {
	out, err := gen.Exec(ctx, f.loader, gen.Input{
		Service: in.Service,
		Inputs:  in.Inputs,
		Out:     in.Out,
		Plugins: f.plugins,
	})
	if err != nil {
		return gcppkg.GenerateOutput{}, err
	}
	return gcppkg.GenerateOutput{Dir: out.Dir, Files: out.Files}, nil
}

func (f *facade) InferColumns(ctx context.Context, in gcppkg.InferInput) (gcppkg.InferOutput, error) {
	kind, err := columns.Kind()
	if err != nil {
		return gcppkg.InferOutput{}, err
	}
	out, err := infer.Exec(ctx, f.loader, kind, infer.Input{
		Service:   in.Service,
		Resources: in.Resources,
		Out:       in.Out,
		WorkDir:   in.WorkDir,
		Model:     in.Model,
		Limit:     in.Limit,
		Force:     in.Force,
		Progress:  f.progress,
	})
	if err != nil {
		return gcppkg.InferOutput{}, err
	}
	return gcppkg.InferOutput{Out: out.Out, WorkDir: out.WorkDir, Files: out.Files}, nil
}
