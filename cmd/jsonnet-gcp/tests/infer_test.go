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

func TestParamsInferUsesCachedResults(t *testing.T) {
	given, when, then := scenario(t)

	given.
		the_service("storage").and().
		a_cached_params_result("storage.buckets.list", `{"confidence":"high","method":"storage.buckets.list","params":[{"name":"prefix","reason":"Restricts results to bucket names with this prefix.","role":"filter"},{"name":"projection","reason":"Controls which properties each bucket includes.","role":"shaping"},{"name":"returnPartialSuccess","reason":"Adds names of buckets in unreachable locations to the response.","role":"shaping"},{"name":"softDeleted","reason":"Limits results to soft-deleted bucket versions when true.","role":"filter"},{"name":"userProject","reason":"Specifies the project billed for the request.","role":"other"}],"reason":"Classifications follow each parameter\u2019s stated effect on the returned buckets, response contents, or request billing."}`).and().
		a_cached_params_result("storage.objects.list", `{"confidence":"high","method":"storage.objects.list","params":[{"name":"delimiter","reason":"Groups deeper object names into prefixes.","role":"shaping"},{"name":"endOffset","reason":"Restricts names to those before this boundary.","role":"filter"},{"name":"filter","reason":"Filters the returned objects.","role":"filter"},{"name":"includeFoldersAsPrefixes","reason":"Adds folders and managed folders to returned prefixes.","role":"shaping"},{"name":"includeTrailingDelimiter","reason":"Adds trailing-delimiter objects to the items.","role":"shaping"},{"name":"matchGlob","reason":"Restricts results to names matching the glob.","role":"filter"},{"name":"prefix","reason":"Restricts results to names beginning with this prefix.","role":"filter"},{"name":"projection","reason":"Controls which properties each object returns.","role":"shaping"},{"name":"softDeleted","reason":"Restricts results to soft-deleted versions.","role":"filter"},{"name":"startOffset","reason":"Restricts names to those at or after this boundary.","role":"filter"},{"name":"userProject","reason":"Specifies the project billed for the request.","role":"other"},{"name":"versions","reason":"Includes all object versions as distinct results.","role":"filter"}],"reason":"Classified each parameter by whether it filters listed results, changes response content, or serves a request-level purpose."}`)

	when.
		the_params_are_inferred()

	then.
		there_is_no_error().and().
		codex_was_called_for().and().
		the_output_is(`[
			  {
			    "method": "storage.buckets.list",
			    "params": [
			      {
			        "name": "prefix",
			        "role": "filter"
			      },
			      {
			        "name": "projection",
			        "role": "shaping"
			      },
			      {
			        "name": "returnPartialSuccess",
			        "role": "shaping"
			      },
			      {
			        "name": "softDeleted",
			        "role": "filter"
			      },
			      {
			        "name": "userProject",
			        "role": "other"
			      }
			    ]
			  },
			  {
			    "method": "storage.objects.list",
			    "params": [
			      {
			        "name": "delimiter",
			        "role": "shaping"
			      },
			      {
			        "name": "endOffset",
			        "role": "filter"
			      },
			      {
			        "name": "filter",
			        "role": "filter"
			      },
			      {
			        "name": "includeFoldersAsPrefixes",
			        "role": "shaping"
			      },
			      {
			        "name": "includeTrailingDelimiter",
			        "role": "shaping"
			      },
			      {
			        "name": "matchGlob",
			        "role": "filter"
			      },
			      {
			        "name": "prefix",
			        "role": "filter"
			      },
			      {
			        "name": "projection",
			        "role": "shaping"
			      },
			      {
			        "name": "softDeleted",
			        "role": "filter"
			      },
			      {
			        "name": "startOffset",
			        "role": "filter"
			      },
			      {
			        "name": "userProject",
			        "role": "other"
			      },
			      {
			        "name": "versions",
			        "role": "filter"
			      }
			    ]
			  }
			]`)
}
