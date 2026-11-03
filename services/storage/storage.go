package storage

import (
	_ "embed"

	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
)

//go:embed storage.json
var model []byte

var Service = gcp.Definition{
	Model: model,
}
