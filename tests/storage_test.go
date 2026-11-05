//go:build e2e

package tests

import "testing"

const storagePrelude = `
local gcp = import 'main.libsonnet';
local ctx = import 'ctx.libsonnet';
local call(method, params={}) = gcp.call(ctx, 'storage', method, params);
local bucket(name) = ctx.project + '-' + name;
`

func TestListBucketsOfProject(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_bucket("logs").and().
		a_bucket("assets")

	when.
		the_jsonnet_is_evaluated(storagePrelude + `
			{ [std.strReplace(b.name, ctx.project + '-', '')]: b.location for b in call('storage.buckets.list').items }
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"assets": "EU", "logs": "EU"}`)
}

func TestListObjectsWithPrefixAndDelimiter(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_bucket("logs").and().
		an_object("logs", "app/2026/a.log", "a").and().
		an_object("logs", "app/2026/b.log", "bb").and().
		an_object("logs", "web/c.log", "ccc").and().
		an_object("logs", "readme.md", "dddd")

	when.
		the_jsonnet_is_evaluated(storagePrelude + `
			local nested = call('storage.objects.list', { bucket: bucket('logs'), prefix: 'app/' });
			local top = call('storage.objects.list', { bucket: bucket('logs'), delimiter: '/' });
			{
			  nested: [{ name: o.name, size: o.size } for o in nested.items],
			  files: [o.name for o in top.items],
			  folders: top.prefixes,
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{
			"nested": [{"name": "app/2026/a.log", "size": "1"}, {"name": "app/2026/b.log", "size": "2"}],
			"files": ["readme.md"],
			"folders": ["app/", "web/"]
		}`)
}

func TestObjectMetadataButNotMedia(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_bucket("logs").and().
		an_object("logs", "app/a+b c.log", "hello")

	when.
		the_jsonnet_is_evaluated(storagePrelude + `
			local object = { bucket: bucket('logs'), object: 'app/a+b c.log' };
			{
			  size: call('storage.objects.get', object).size,
			  media: call('storage.objects.get', object { alt: 'media' })._failure.code,
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"size": "5", "media": 400}`)
}
