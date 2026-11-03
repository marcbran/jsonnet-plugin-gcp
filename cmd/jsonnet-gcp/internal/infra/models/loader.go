package models

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
)

type Loader struct {
	services []gcp.Definition
}

func NewLoader(services ...gcp.Definition) *Loader {
	return &Loader{services: services}
}

func (l *Loader) LoadModel(ctx context.Context, service string) (string, error) {
	for _, def := range l.services {
		svc, err := gcp.LoadService(def)
		if err != nil {
			return "", err
		}
		if svc.Key != service {
			continue
		}
		model, err := readModel(svc, def.Model)
		if err != nil {
			return "", err
		}
		raw, err := json.Marshal(model)
		if err != nil {
			return "", err
		}
		return string(raw), nil
	}
	return "", fmt.Errorf("unknown service %s", service)
}
