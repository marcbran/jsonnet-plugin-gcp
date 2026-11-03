package gcp

import (
	"fmt"
	"maps"
	"net/url"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

const projectParam = "project"

var pathVar = regexp.MustCompile(`\{(\+?)([^}]+)\}`)

type request struct {
	Path  string
	Query url.Values
}

func encode(m *Method, ci CallInput) (request, error) {
	values := map[string]any{}
	for name, v := range ci.Params {
		if name == projectParam {
			return request{}, fmt.Errorf("%s comes from ctx, not params", projectParam)
		}
		_, ok := m.Parameters[name]
		if !ok {
			return request{}, fmt.Errorf("unknown parameter %s", name)
		}
		if v != nil {
			values[name] = v
		}
	}
	_, ok := m.Parameters[projectParam]
	if ok {
		values[projectParam] = ci.Project
	}
	for name, p := range m.Parameters {
		_, ok := values[name]
		if p.Required && !ok {
			return request{}, fmt.Errorf("missing required parameter %s", name)
		}
	}
	path, err := expandPath(m.Path, values)
	if err != nil {
		return request{}, err
	}
	query := url.Values{}
	for _, name := range slices.Sorted(maps.Keys(values)) {
		p := m.Parameters[name]
		if p.Location != "query" {
			continue
		}
		strs, err := queryValues(name, p, values[name])
		if err != nil {
			return request{}, err
		}
		query[name] = strs
	}
	return request{Path: path, Query: query}, nil
}

func expandPath(template string, values map[string]any) (string, error) {
	var err error
	path := pathVar.ReplaceAllStringFunc(template, func(match string) string {
		groups := pathVar.FindStringSubmatch(match)
		reserved, name := groups[1] == "+", groups[2]
		v, ok := values[name]
		if !ok {
			err = fmt.Errorf("missing path parameter %s", name)
			return ""
		}
		s, convErr := scalarString(v)
		if convErr != nil {
			err = fmt.Errorf("parameter %s: %w", name, convErr)
			return ""
		}
		if !reserved {
			return url.PathEscape(s)
		}
		parts := strings.Split(s, "/")
		for i, part := range parts {
			parts[i] = url.PathEscape(part)
		}
		return strings.Join(parts, "/")
	})
	return path, err
}

func queryValues(name string, p Parameter, v any) ([]string, error) {
	items, isList := v.([]any)
	if !isList {
		s, err := scalarString(v)
		if err != nil {
			return nil, fmt.Errorf("parameter %s: %w", name, err)
		}
		return []string{s}, nil
	}
	if !p.Repeated {
		return nil, fmt.Errorf("parameter %s is not repeated", name)
	}
	strs := make([]string, 0, len(items))
	for _, item := range items {
		s, err := scalarString(item)
		if err != nil {
			return nil, fmt.Errorf("parameter %s: %w", name, err)
		}
		strs = append(strs, s)
	}
	return strs, nil
}

func scalarString(v any) (string, error) {
	switch t := v.(type) {
	case string:
		return t, nil
	case bool:
		return strconv.FormatBool(t), nil
	case float64:
		return strconv.FormatFloat(t, 'f', -1, 64), nil
	default:
		return "", fmt.Errorf("must be a string, number or boolean")
	}
}
