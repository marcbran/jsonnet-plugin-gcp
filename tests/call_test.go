//go:build e2e

package tests

import "testing"

func TestInvalidCallsReturnStatus(t *testing.T) {
	_, when, then := scenario(t)

	when.
		the_jsonnet_is_evaluated(`
			local gcp = import 'main.libsonnet';
			local ctx = import 'ctx.libsonnet';
			{
			  noProject: gcp.call({}, 'compute', 'compute.zones.list')._failure.message,
			  projectParam: gcp.call(ctx, 'compute', 'compute.zones.list', { project: 'other' })._failure.message,
			  missingParam: gcp.call(ctx, 'compute', 'compute.instances.list')._failure.message,
			  unknownParam: gcp.call(ctx, 'compute', 'compute.zones.list', { alt: 'media' })._failure.message,
			  unknownMethod: gcp.call(ctx, 'compute', 'compute.nothing.list')._failure.message,
			  unknownService: gcp.call(ctx, 'run', 'run.projects.locations.services.list')._failure.message,
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{
			"noProject": "ctx.project must be a non-empty string",
			"projectParam": "compute.zones.list: project comes from ctx, not params",
			"missingParam": "compute.instances.list: missing required parameter zone",
			"unknownParam": "compute.zones.list: unknown parameter alt",
			"unknownMethod": "compute has no method compute.nothing.list",
			"unknownService": "unknown service run"
		}`)
}
