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
    rm -rf arcourse/build && {{tool}} jpoet pkg build arcourse
    for dir in services/*/arcourse/; do rm -rf "$dir/build" && {{tool}} jpoet pkg build "$dir" || exit 1; done

push: build
    {{tool}} jpoet pkg push
    {{tool}} jpoet pkg push arcourse
    for dir in services/*/arcourse/; do {{tool}} jpoet pkg push "$dir" || exit 1; done

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

arcourse-gen service:
    go run ./cmd/jsonnet-gcp gen "{{service}}" --inputs "services/{{service}}/inference" --out "services/{{service}}/arcourse"

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
