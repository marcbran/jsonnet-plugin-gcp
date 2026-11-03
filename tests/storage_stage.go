//go:build e2e

package tests

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/stretchr/testify/require"
)

func (s *Stage) a_bucket(name string) *Stage {
	_, err := flociRequest(http.MethodPost, "/storage/v1/b?project="+url.QueryEscape(s.project), "application/json",
		fmt.Appendf(nil, `{"name": %q, "location": "EU"}`, s.bucket(name)))
	require.NoError(s.t, err)
	return s
}

func (s *Stage) an_object(bucket string, name string, body string) *Stage {
	path := fmt.Sprintf("/upload/storage/v1/b/%s/o?uploadType=media&name=%s", url.PathEscape(s.bucket(bucket)), url.QueryEscape(name))
	_, err := flociRequest(http.MethodPost, path, "text/plain", []byte(body))
	require.NoError(s.t, err)
	return s
}

func (s *Stage) bucket(name string) string {
	return s.project + "-" + name
}
