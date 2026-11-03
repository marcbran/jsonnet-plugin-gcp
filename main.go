package main

import (
	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
	"github.com/marcbran/jsonnet-plugin-gcp/services"
)

func main() {
	gcp.Plugin(gcp.WithServices(services.All()...)).Serve()
}
