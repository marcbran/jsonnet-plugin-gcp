package cmd

import (
	"fmt"
	"os"

	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/infra/models"
	"github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/internal/jsonnetgcp"
	gcppkg "github.com/marcbran/jsonnet-plugin-gcp/cmd/jsonnet-gcp/pkg/jsonnetgcp"
	"github.com/marcbran/jsonnet-plugin-gcp/services"
	jsonnetplugin "github.com/marcbran/jsonnet-plugin-jsonnet/jsonnet"
	"github.com/spf13/cobra"
)

var genCmd = &cobra.Command{
	Use:   "gen SERVICE",
	Short: "Generate arcourse nodes for a Google Cloud API from its Discovery document, resources and columns",
	Args:  cobra.ExactArgs(1),
	RunE:  runGen,
}

func init() {
	genCmd.Flags().String("inputs", "", "directory with resources.json and columns.json (default: ./SERVICE/inference)")
	genCmd.Flags().StringP("out", "o", "", "package directory main.libsonnet, pkg.libsonnet and mixins.libsonnet are written into (default: ./SERVICE/arcourse)")
}

func runGen(cmd *cobra.Command, args []string) error {
	cmd.SilenceUsage = true
	cmd.SilenceErrors = true

	inputs, err := cmd.Flags().GetString("inputs")
	if err != nil {
		return err
	}
	out, err := cmd.Flags().GetString("out")
	if err != nil {
		return err
	}
	facade := jsonnetgcp.NewFacade(models.NewLoader(services.All()...), nil, jsonnetplugin.Plugin())
	result, err := facade.Generate(cmd.Context(), gcppkg.GenerateInput{Service: args[0], Inputs: inputs, Out: out})
	if err != nil {
		return err
	}
	for _, file := range result.Files {
		_, err = fmt.Fprintln(os.Stdout, file)
		if err != nil {
			return err
		}
	}
	return nil
}
