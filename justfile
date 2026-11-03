tool := "go tool -modfile=tools/go.mod"

models_ref := "b58e90f69f46d1ee010bb686e134574f648c2326"

test-go:
    go test -v -cover -timeout=120s -parallel=10 ./...

test-jsonnet:
    {{tool}} jpoet test .

test: test-go test-jsonnet

lint-go:
    {{tool}} golangci-lint run ./...

lint: lint-go

vuln-go:
    {{tool}} govulncheck ./...

vuln: vuln-go

build:
    {{tool}} jpoet pkg build

push: build
    {{tool}} jpoet pkg push

update-models:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in services/*/; do
      api=$(basename "$dir")
      version=$(jq -r '.version' "$dir/$api.json")
      curl -fsSL -o "$dir/$api.json" "https://raw.githubusercontent.com/googleapis/google-api-go-client/{{models_ref}}/$api/$version/$api-api.json"
    done

add-model api version="v1":
    mkdir -p "services/{{api}}"
    curl -fsSL -o "services/{{api}}/{{api}}.json" "https://raw.githubusercontent.com/googleapis/google-api-go-client/{{models_ref}}/{{api}}/{{version}}/{{api}}-api.json"

test-e2e:
    go test -v -tags e2e ./tests/...

ci: lint vuln test build test-e2e
