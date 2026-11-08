tool := "go tool -modfile=tools/go.mod"

models_ref := "b58e90f69f46d1ee010bb686e134574f648c2326"

add-model api version="v1":
    mkdir -p "services/{{api}}"
    curl -fsSL -o "services/{{api}}/{{api}}.json" "https://raw.githubusercontent.com/googleapis/google-api-go-client/{{models_ref}}/{{api}}/{{version}}/{{api}}-api.json"

arcourse-gen service:
    go run ./cmd/jsonnet-gcp gen "{{service}}" --inputs "services/{{service}}/inference" --out "pkg/arcourse-gcp-{{service}}"

arcourse-infer service:
    #!/usr/bin/env bash
    set -euo pipefail
    extra=()
    if [ -n "${LIMIT:-}" ]; then extra+=(--limit "$LIMIT"); fi
    if [ -n "${MODEL:-}" ]; then extra+=(--model "$MODEL"); fi
    if [ "${FORCE:-}" = "1" ]; then extra+=(--force); fi
    go run ./cmd/jsonnet-gcp columns infer "{{service}}" \
      --workdir "services/{{service}}/inference" \
      "${extra[@]+"${extra[@]}"}"

arcourse-infer-service service: (arcourse-infer service) (arcourse-gen service)

build-jsonnet: vendor-jsonnet
    for dir in pkg/*/; do \
        [ -f "$dir/main.libsonnet" ] || continue; \
        rm -rf "$dir/build" && {{tool}} jpoet pkg build -J "${dir}vendor" "$dir" || exit 1; \
    done

build: build-jsonnet

ci: lint vuln test build test-e2e

lint-go:
    {{tool}} golangci-lint run ./...

lint: lint-go

push-jsonnet: build-jsonnet
    for dir in pkg/*/; do \
        [ -f "$dir/main.libsonnet" ] || continue; \
        {{tool}} jpoet pkg push "$dir" || exit 1; \
    done

push: push-jsonnet

test-e2e:
    go test -v -tags e2e ./tests/...

test-go:
    go test -v -cover -timeout=120s -parallel=10 ./...

test-jsonnet: vendor-jsonnet
    for dir in pkg/*/; do \
        [ -f "$dir/main.libsonnet" ] || continue; \
        {{tool}} jpoet test -J "${dir}vendor" "$dir" || exit 1; \
    done

test: test-go test-jsonnet

update-models:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in services/*/; do
      api=$(basename "$dir")
      version=$(jq -r '.version' "$dir/$api.json")
      curl -fsSL -o "$dir/$api.json" "https://raw.githubusercontent.com/googleapis/google-api-go-client/{{models_ref}}/$api/$version/$api-api.json"
    done

vendor-jsonnet:
    for dir in pkg/*/; do \
        [ -f "$dir/jsonnetfile.json" ] || continue; \
        (cd "$dir" && go tool -modfile=../../tools/go.mod jb install) || exit 1; \
    done

vuln-go:
    {{tool}} govulncheck ./...

vuln: vuln-go
