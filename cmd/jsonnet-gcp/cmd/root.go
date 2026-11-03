package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var version = "dev"

var rootCmd = &cobra.Command{
	Use:   "jsonnet-gcp",
	Short: "Generate arcourse nodes and infer columns from Google Cloud Discovery documents",
}

func init() {
	rootCmd.PersistentFlags().BoolP("quiet", "q", false, "Suppress progress messages on stderr")
	rootCmd.AddCommand(genCmd)
	rootCmd.AddCommand(columnsCmd)
	rootCmd.Version = version
}

func Execute() {
	err := rootCmd.Execute()
	if err == nil {
		return
	}
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
