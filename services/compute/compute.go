package compute

import (
	_ "embed"

	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
)

//go:embed compute.json
var model []byte

var Service = gcp.Definition{
	Model: model,
	DeniedMethods: []string{
		"compute.instances.getGuestAttributes",
		"compute.instances.getScreenshot",
		"compute.instances.getSerialPortOutput",
	},
}
