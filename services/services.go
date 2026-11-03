package services

import (
	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
	"github.com/marcbran/jsonnet-plugin-gcp/services/compute"
	"github.com/marcbran/jsonnet-plugin-gcp/services/storage"
)

func All() []gcp.Definition {
	return []gcp.Definition{compute.Service, storage.Service}
}
