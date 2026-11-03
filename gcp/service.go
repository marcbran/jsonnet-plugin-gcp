package gcp

import (
	"encoding/json"
	"fmt"
	"net/http"
	"slices"
	"sync"
)

type Definition struct {
	Model         []byte
	DeniedMethods []string
}

type Service struct {
	Key         string
	Version     string
	RootURL     string
	ServicePath string
	methods     map[string]*Method
	denied      []string
}

type Method struct {
	ID         string               `json:"id"`
	Path       string               `json:"path"`
	HTTPMethod string               `json:"httpMethod"`
	Parameters map[string]Parameter `json:"parameters"`
}

type Parameter struct {
	Type     string `json:"type"`
	Location string `json:"location"`
	Required bool   `json:"required"`
	Repeated bool   `json:"repeated"`
}

type document struct {
	Name        string             `json:"name"`
	Version     string             `json:"version"`
	RootURL     string             `json:"rootUrl"`
	ServicePath string             `json:"servicePath"`
	Methods     map[string]*Method `json:"methods"`
	Resources   map[string]*resource `json:"resources"`
}

type resource struct {
	Methods   map[string]*Method   `json:"methods"`
	Resources map[string]*resource `json:"resources"`
}

func (s *Service) Method(id string) (*Method, error) {
	m, ok := s.methods[id]
	if !ok {
		return nil, fmt.Errorf("%s has no method %s", s.Key, id)
	}
	return m, nil
}

func (s *Service) Readable(m *Method) bool {
	return m.HTTPMethod == http.MethodGet && !slices.Contains(s.denied, m.ID)
}

func LoadService(def Definition) (*Service, error) {
	var doc document
	err := json.Unmarshal(def.Model, &doc)
	if err != nil {
		return nil, fmt.Errorf("parse discovery document: %w", err)
	}
	if doc.Name == "" {
		return nil, fmt.Errorf("discovery document has no name")
	}
	svc := &Service{
		Key:         doc.Name,
		Version:     doc.Version,
		RootURL:     doc.RootURL,
		ServicePath: doc.ServicePath,
		methods:     map[string]*Method{},
		denied:      def.DeniedMethods,
	}
	collectMethods(svc.methods, doc.Methods, doc.Resources)
	return svc, nil
}

func collectMethods(out map[string]*Method, methods map[string]*Method, resources map[string]*resource) {
	for _, m := range methods {
		out[m.ID] = m
	}
	for _, r := range resources {
		collectMethods(out, r.Methods, r.Resources)
	}
}

type registry struct {
	definitions []Definition
	once        sync.Once
	services    map[string]*Service
	err         error
}

func (r *registry) service(key string) (*Service, error) {
	r.once.Do(r.load)
	if r.err != nil {
		return nil, r.err
	}
	svc, ok := r.services[key]
	if !ok {
		return nil, fmt.Errorf("unknown service %s", key)
	}
	return svc, nil
}

func (r *registry) load() {
	r.services = map[string]*Service{}
	for _, def := range r.definitions {
		svc, err := LoadService(def)
		if err != nil {
			r.err = err
			return
		}
		r.services[svc.Key] = svc
	}
}
