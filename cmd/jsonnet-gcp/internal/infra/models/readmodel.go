package models

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"

	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
)

type Model struct {
	Name        string             `json:"name"`
	Title       string             `json:"title"`
	Version     string             `json:"version"`
	ServicePath string             `json:"servicePath"`
	Methods     map[string]Method  `json:"methods"`
	Schemas     map[string]*Schema `json:"schemas"`
}

type Method struct {
	ID         string               `json:"id"`
	Resource   string               `json:"resource"`
	Name       string               `json:"name"`
	Path       string               `json:"path"`
	Parameters map[string]Parameter `json:"parameters"`
	Response   string               `json:"response,omitempty"`
}

type Parameter struct {
	Type     string `json:"type"`
	Location string `json:"location"`
	Required bool   `json:"required,omitempty"`
	Repeated bool   `json:"repeated,omitempty"`
}

type Schema struct {
	Ref                  string             `json:"$ref,omitempty"`
	Type                 string             `json:"type,omitempty"`
	Description          string             `json:"description,omitempty"`
	Reference            bool               `json:"x-reference,omitempty"`
	Format               string             `json:"format,omitempty"`
	Enum                 []string           `json:"enum,omitempty"`
	Properties           map[string]*Schema `json:"properties,omitempty"`
	Items                *Schema            `json:"items,omitempty"`
	AdditionalProperties *Schema            `json:"additionalProperties,omitempty"`
}

type document struct {
	Name        string               `json:"name"`
	Title       string               `json:"title"`
	Version     string               `json:"version"`
	ServicePath string               `json:"servicePath"`
	Methods     map[string]*method   `json:"methods"`
	Resources   map[string]*resource `json:"resources"`
	Schemas     map[string]*Schema   `json:"schemas"`
}

type resource struct {
	Methods   map[string]*method   `json:"methods"`
	Resources map[string]*resource `json:"resources"`
}

type method struct {
	ID         string               `json:"id"`
	Path       string               `json:"path"`
	Parameters map[string]Parameter `json:"parameters"`
	Response   *struct {
		Ref string `json:"$ref"`
	} `json:"response"`
}

func readModel(svc *gcp.Service, raw []byte) (*Model, error) {
	var doc document
	err := json.Unmarshal(raw, &doc)
	if err != nil {
		return nil, fmt.Errorf("parse discovery document: %w", err)
	}
	out := &Model{
		Name:        doc.Name,
		Title:       doc.Title,
		Version:     doc.Version,
		ServicePath: doc.ServicePath,
		Methods:     map[string]Method{},
		Schemas:     doc.Schemas,
	}
	err = collect(svc, out.Methods, nil, doc.Methods, doc.Resources)
	if err != nil {
		return nil, err
	}
	for _, schema := range out.Schemas {
		markReferences(schema)
	}
	return out, nil
}

var referenceDescription = regexp.MustCompile(`\bURL (of|reference)\b`)

func markReferences(s *Schema) {
	if s == nil {
		return
	}
	s.Reference = s.Type == "string" && referenceDescription.MatchString(s.Description)
	s.Description = ""
	for _, p := range s.Properties {
		markReferences(p)
	}
	markReferences(s.Items)
	markReferences(s.AdditionalProperties)
}

func collect(svc *gcp.Service, out map[string]Method, resourcePath []string, methods map[string]*method, resources map[string]*resource) error {
	for name, m := range methods {
		gm, err := svc.Method(m.ID)
		if err != nil {
			return err
		}
		if !svc.Readable(gm) {
			continue
		}
		rm := Method{
			ID:         m.ID,
			Resource:   strings.Join(resourcePath, "."),
			Name:       name,
			Path:       m.Path,
			Parameters: m.Parameters,
		}
		if m.Response != nil {
			rm.Response = m.Response.Ref
		}
		out[m.ID] = rm
	}
	for name, r := range resources {
		err := collect(svc, out, append(append([]string{}, resourcePath...), name), r.Methods, r.Resources)
		if err != nil {
			return err
		}
	}
	return nil
}
