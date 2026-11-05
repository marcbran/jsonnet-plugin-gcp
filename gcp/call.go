package gcp

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"github.com/marcbran/jpoet/pkg/jpoet"
)

type CallInput struct {
	Project string
	Service string
	Method  string
	Params  map[string]any
}

func Call(cfg *Config) jsonnet.NativeFunction {
	return jsonnet.NativeFunction{
		Name:   "call",
		Params: ast.Identifiers{"ctx", "service", "method", "params"},
		Func: func(args []any) (any, error) {
			ci, err := parseCallInput(args)
			if err != nil {
				return nil, jpoet.NewFailure(http.StatusBadRequest, err.Error())
			}
			return runCall(context.Background(), cfg, ci)
		},
	}
}

func parseCallInput(args []any) (CallInput, error) {
	if len(args) != 4 {
		return CallInput{}, fmt.Errorf("expected ctx, service, method, and params")
	}
	ctx, ok := args[0].(map[string]any)
	if !ok {
		return CallInput{}, fmt.Errorf("ctx must be an object")
	}
	project, ok := ctx["project"].(string)
	if !ok || project == "" {
		return CallInput{}, fmt.Errorf("ctx.project must be a non-empty string")
	}
	service, ok := args[1].(string)
	if !ok || service == "" {
		return CallInput{}, fmt.Errorf("service must be a non-empty string")
	}
	method, ok := args[2].(string)
	if !ok || method == "" {
		return CallInput{}, fmt.Errorf("method must be a non-empty string")
	}
	params := map[string]any{}
	if args[3] != nil {
		params, ok = args[3].(map[string]any)
		if !ok {
			return CallInput{}, fmt.Errorf("params must be an object")
		}
	}
	return CallInput{
		Project: project,
		Service: service,
		Method:  method,
		Params:  params,
	}, nil
}

func runCall(ctx context.Context, cfg *Config, ci CallInput) (any, error) {
	svc, err := cfg.registry.service(ci.Service)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadRequest, err.Error())
	}
	m, err := svc.Method(ci.Method)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadRequest, err.Error())
	}
	if !svc.Readable(m) {
		return nil, jpoet.NewFailure(http.StatusForbidden, fmt.Sprintf("%s is not an allowed read method", m.ID))
	}
	endpoint, err := cfg.Endpoint(svc)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadRequest, err.Error())
	}
	req, err := encode(m, ci)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadRequest, fmt.Sprintf("%s: %s", m.ID, err))
	}
	creds, err := cfg.Credentials(ctx, ci)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusUnauthorized, err.Error())
	}
	url := endpoint + "/" + svc.ServicePath + req.Path
	if len(req.Query) > 0 {
		url += "?" + req.Query.Encode()
	}
	httpReq, err := http.NewRequestWithContext(ctx, m.HTTPMethod, url, nil)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadRequest, err.Error())
	}
	httpReq.Header.Set("Accept", "application/json")
	if creds.Token != "" {
		httpReq.Header.Set("Authorization", "Bearer "+creds.Token)
	}
	httpResp, err := cfg.Client.Do(httpReq)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadGateway, err.Error())
	}
	body, err := io.ReadAll(httpResp.Body)
	closeErr := httpResp.Body.Close()
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadGateway, err.Error())
	}
	if closeErr != nil {
		return nil, jpoet.NewFailure(http.StatusBadGateway, closeErr.Error())
	}
	if httpResp.StatusCode < 200 || httpResp.StatusCode > 299 {
		reason, msg := decodeError(body)
		return nil, &jpoet.Failure{Code: httpResp.StatusCode, Reason: reason, Message: msg}
	}
	if len(body) == 0 {
		return map[string]any{}, nil
	}
	var out any
	err = json.Unmarshal(body, &out)
	if err != nil {
		return nil, jpoet.NewFailure(http.StatusBadGateway, fmt.Sprintf("decode response: %s", err))
	}
	return out, nil
}

type errorBody struct {
	Error struct {
		Message string `json:"message"`
		Status  string `json:"status"`
		Errors  []struct {
			Reason string `json:"reason"`
		} `json:"errors"`
	} `json:"error"`
}

func decodeError(body []byte) (string, string) {
	var e errorBody
	err := json.Unmarshal(body, &e)
	if err != nil || e.Error.Message == "" {
		return "", string(body)
	}
	reason := e.Error.Status
	if reason == "" && len(e.Error.Errors) > 0 {
		reason = e.Error.Errors[0].Reason
	}
	return reason, e.Error.Message
}
