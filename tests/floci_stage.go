//go:build e2e

package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync/atomic"
	"time"

	"github.com/marcbran/jsonnet-plugin-gcp/gcp"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

const (
	flociImage   = "floci/floci-gcp:0.12.0"
	flociPort    = "4588/tcp"
	flociRegion  = "europe-west1"
	flociLinkURL = "https://www.googleapis.com"
)

var flociEndpoint string

var lastFlociProject atomic.Int64

func startFloci(ctx context.Context) (testcontainers.Container, error) {
	container, err := testcontainers.Run(ctx, flociImage,
		testcontainers.WithExposedPorts(flociPort),
		testcontainers.WithEnv(map[string]string{
			"FLOCI_GCP_SERVICES_COMPUTE_REGIONS": flociRegion,
		}),
		testcontainers.WithWaitStrategy(
			wait.ForHTTP("/_floci-gcp/health").WithPort(flociPort).WithStartupTimeout(2*time.Minute),
		),
	)
	if err != nil {
		return container, err
	}
	endpoint, err := container.PortEndpoint(ctx, flociPort, "http")
	if err != nil {
		return container, err
	}
	flociEndpoint = endpoint
	return container, nil
}

func newFlociProject() string {
	return fmt.Sprintf("e2e-project-%d", lastFlociProject.Add(1))
}

func flociCredentials(project string) gcp.Credentials {
	return gcp.Credentials{Token: "floci-" + project}
}

func flociRequest(method string, path string, contentType string, body []byte) (map[string]any, error) {
	req, err := http.NewRequest(method, flociEndpoint+path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer floci")
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }()
	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return nil, fmt.Errorf("%s %s: %d %s", method, path, resp.StatusCode, raw)
	}
	out := map[string]any{}
	if len(raw) == 0 {
		return out, nil
	}
	err = json.Unmarshal(raw, &out)
	return out, err
}

func flociInsert(path string, resource map[string]any) error {
	body, err := json.Marshal(resource)
	if err != nil {
		return err
	}
	op, err := flociRequest(http.MethodPost, path, "application/json", body)
	if err != nil {
		return err
	}
	return flociWait(op)
}

func flociWait(op map[string]any) error {
	deadline := time.Now().Add(30 * time.Second)
	for {
		if errs, ok := op["error"]; ok {
			return fmt.Errorf("operation failed: %v", errs)
		}
		if op["status"] == "DONE" {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("operation %v did not finish", op["name"])
		}
		link, ok := op["selfLink"].(string)
		if !ok {
			return fmt.Errorf("operation has no selfLink: %v", op)
		}
		time.Sleep(50 * time.Millisecond)
		next, err := flociRequest(http.MethodGet, strings.TrimPrefix(link, flociLinkURL), "", nil)
		if err != nil {
			return err
		}
		op = next
	}
}
