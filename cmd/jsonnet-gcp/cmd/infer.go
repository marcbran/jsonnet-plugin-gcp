package cmd

import (
	"context"
	"fmt"
	"os"

	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/infra/models"
	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/jsonnetgcp"
	gcppkg "github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/pkg/jsonnetgcp"
	"github.com/marcbran/jsonnet-plugin-gcp/services"
	"github.com/spf13/cobra"
)

type inferFunc func(f gcppkg.Facade, ctx context.Context, in gcppkg.InferInput) (gcppkg.InferOutput, error)

func newInferCmd(kind string, short string, run inferFunc) *cobra.Command {
	parent := &cobra.Command{
		Use:   kind,
		Short: short,
	}
	infer := &cobra.Command{
		Use:   "infer SERVICE",
		Short: fmt.Sprintf("Infer %s for a Google Cloud API", kind),
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runInfer(cmd, args[0], kind, run)
		},
	}
	infer.Flags().StringP("out", "o", "", fmt.Sprintf("output JSON file (default: <workdir>/%s.json)", kind))
	infer.Flags().String("workdir", "", "working directory for inference bundles and cached results (default: ./SERVICE)")
	infer.Flags().String("resources", "", "resources included in the tree (default: <workdir>/resources.json, if present)")
	infer.Flags().String("model", "", "Codex model to use for inference (default: the model configured in codex)")
	infer.Flags().Int("limit", 0, "maximum number of new Codex calls; 0 means unlimited")
	infer.Flags().Bool("force", false, "re-run Codex calls even when result files already exist")
	parent.AddCommand(infer)
	return parent
}

func runInfer(cmd *cobra.Command, service string, kind string, run inferFunc) error {
	cmd.SilenceUsage = true
	cmd.SilenceErrors = true

	in := gcppkg.InferInput{Service: service}
	var err error
	in.Out, err = cmd.Flags().GetString("out")
	if err != nil {
		return err
	}
	in.WorkDir, err = cmd.Flags().GetString("workdir")
	if err != nil {
		return err
	}
	in.Resources, err = cmd.Flags().GetString("resources")
	if err != nil {
		return err
	}
	in.Model, err = cmd.Flags().GetString("model")
	if err != nil {
		return err
	}
	in.Limit, err = cmd.Flags().GetInt("limit")
	if err != nil {
		return err
	}
	in.Force, err = cmd.Flags().GetBool("force")
	if err != nil {
		return err
	}
	quiet, err := cmd.Flags().GetBool("quiet")
	if err != nil {
		return err
	}

	var progress func(jobName, taskID string, cached bool)
	if !quiet {
		_, err = fmt.Fprintf(os.Stderr, "inferring %s for %s\n", kind, service)
		if err != nil {
			return err
		}
		progress = func(jobName, taskID string, cached bool) {
			if cached {
				fmt.Fprintf(os.Stderr, "  [cached]  %s/%s\n", jobName, taskID)
			} else {
				fmt.Fprintf(os.Stderr, "  [running] %s/%s\n", jobName, taskID)
			}
		}
	}

	facade := jsonnetgcp.NewFacade(models.NewLoader(services.All()...), progress)
	out, err := run(facade, cmd.Context(), in)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintln(os.Stdout, out.Out)
	return err
}

var columnsCmd = newInferCmd("columns", "Work with table columns", gcppkg.Facade.InferColumns)
