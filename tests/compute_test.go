//go:build e2e

package tests

import "testing"

const computePrelude = `
local gcp = import 'main.libsonnet';
local ctx = import 'ctx.libsonnet';
local call(method, params={}) = gcp.call(ctx, 'compute', method, params);
`

func TestListZonesOfConfiguredRegion(t *testing.T) {
	_, when, then := scenario(t)

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			[z.name for z in call('compute.zones.list').items]
		`)

	then.
		there_is_no_error().and().
		the_output_is(`["europe-west1-b", "europe-west1-c", "europe-west1-d"]`)
}

func TestListInstancesInZone(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1", "vm-2"},
			"europe-west1-c": {"vm-3"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local instances = call('compute.instances.list', { zone: 'europe-west1-b' }).items;
			[{ name: i.name, status: i.status, machineType: std.split(i.machineType, '/')[10] } for i in instances]
		`)

	then.
		there_is_no_error().and().
		the_output_is(`[
			{"name": "vm-1", "status": "RUNNING", "machineType": "e2-standard-2"},
			{"name": "vm-2", "status": "RUNNING", "machineType": "e2-standard-2"}
		]`)
}

func TestAggregatedListGroupsInstancesByZone(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1", "vm-2"},
			"europe-west1-c": {"vm-3"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local items = call('compute.instances.aggregatedList').items;
			{ [scope]: [i.name for i in items[scope].instances] for scope in std.objectFields(items) if std.objectHas(items[scope], 'instances') }
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"zones/europe-west1-b": ["vm-1", "vm-2"], "zones/europe-west1-c": ["vm-3"]}`)
}

func TestPageTokenFetchesNextPage(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1", "vm-2", "vm-3"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local page(token) = call('compute.instances.list', { zone: 'europe-west1-b', maxResults: 2, pageToken: token });
			local first = page(null);
			local second = page(first.nextPageToken);
			{
			  first: [i.name for i in first.items],
			  second: [i.name for i in second.items],
			  last: !std.objectHas(second, 'nextPageToken'),
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"first": ["vm-1", "vm-2"], "second": ["vm-3"], "last": true}`)
}

func TestInstanceReferencesAreSelfLinks(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local project = (import 'ctx.libsonnet').project;
			local i = call('compute.instances.get', { zone: 'europe-west1-b', instance: 'vm-1' });
			local base = 'https://www.googleapis.com/compute/v1/projects/' + project + '/';
			{
			  disk: std.strReplace(i.disks[0].source, base, ''),
			  subnetwork: std.strReplace(i.networkInterfaces[0].subnetwork, base, ''),
			  network: std.strReplace(i.networkInterfaces[0].network, base, ''),
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{
			"disk": "zones/europe-west1-b/disks/vm-1",
			"subnetwork": "regions/europe-west1/subnetworks/sub",
			"network": "global/networks/net"
		}`)
}

func TestMissingInstanceReturnsStatus(t *testing.T) {
	_, when, then := scenario(t)

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local s = call('compute.instances.get', { zone: 'europe-west1-b', instance: 'missing' });
			{ code: s._failure.code, reason: s._failure.reason }
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"code": 404, "reason": "NOT_FOUND"}`)
}

func TestProjectsAreIsolated(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local other = import 'other-ctx.libsonnet';
			{
			  own: [i.name for i in call('compute.instances.list', { zone: 'europe-west1-b' }).items],
			  other: std.get(gcp.call(other, 'compute', 'compute.instances.list', { zone: 'europe-west1-b' }), 'items', []),
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"own": ["vm-1"], "other": []}`)
}

func TestDeniedAndMutatingMethodsAreRejected(t *testing.T) {
	given, when, then := scenario(t)

	given.
		a_network_with_instances(map[string][]string{
			"europe-west1-b": {"vm-1"},
		})

	when.
		the_jsonnet_is_evaluated(computePrelude + `
			local instance = { zone: 'europe-west1-b', instance: 'vm-1' };
			{
			  serialPort: call('compute.instances.getSerialPortOutput', instance)._failure.code,
			  delete: call('compute.instances.delete', instance)._failure.code,
			  stillThere: call('compute.instances.get', instance).status,
			}
		`)

	then.
		there_is_no_error().and().
		the_output_is(`{"serialPort": 403, "delete": 403, "stillThere": "RUNNING"}`)
}
