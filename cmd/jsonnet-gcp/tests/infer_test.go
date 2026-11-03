//go:build e2e

package tests

import "testing"

func TestColumnsInferRetriesAndRejectsInvalidColumns(t *testing.T) {
	given, when, then := scenario(t)

	given.
		the_service("storage")

	when.
		the_columns_are_inferred()

	then.
		the_error_mentions("column path [\"doesNotExist\"] does not exist in itemSchema").and().
		codex_was_called_for(
			"storage.buckets.list", "storage.buckets.list",
			"storage.objects.list", "storage.objects.list",
		)
}

func TestColumnsInferUsesCachedResults(t *testing.T) {
	given, when, then := scenario(t)

	given.
		the_service("storage").and().
		a_cached_result("storage.buckets.list", `{"method":"storage.buckets.list","array":["items"],"columns":[{"key":"name","path":["name"],"label":"Name","kind":"name","priority":"primary"},{"key":"location","path":["location"],"label":"Location","kind":"text","priority":"secondary"}],"confidence":"high","reason":"cached"}`).and().
		a_cached_result("storage.objects.list", `{"method":"storage.objects.list","array":["items"],"columns":[{"key":"name","path":["name"],"label":"Name","kind":"name","priority":"primary"},{"key":"size","path":["size"],"label":"Size","kind":"count","priority":"secondary"}],"confidence":"high","reason":"cached"}`)

	when.
		the_columns_are_inferred()

	then.
		there_is_no_error().and().
		codex_was_called_for().and().
		the_output_is(`[
			{"method": "storage.buckets.list", "array": ["items"], "columns": [
				{"key": "name", "path": ["name"], "label": "Name", "kind": "name", "priority": "primary"},
				{"key": "location", "path": ["location"], "label": "Location", "kind": "text", "priority": "secondary"}
			]},
			{"method": "storage.objects.list", "array": ["items"], "columns": [
				{"key": "name", "path": ["name"], "label": "Name", "kind": "name", "priority": "primary"},
				{"key": "size", "path": ["size"], "label": "Size", "kind": "count", "priority": "secondary"}
			]}
		]`)
}
