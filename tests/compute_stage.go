//go:build e2e

package tests

import (
	"fmt"

	"github.com/stretchr/testify/require"
)

const (
	flociMachineType = "e2-standard-2"
	flociBootImage   = "projects/debian-cloud/global/images/family/debian-12"
)

func (s *Stage) a_network(name string) *Stage {
	err := flociInsert(fmt.Sprintf("/compute/v1/projects/%s/global/networks", s.project), map[string]any{
		"name":                  name,
		"autoCreateSubnetworks": false,
	})
	require.NoError(s.t, err)
	return s
}

func (s *Stage) a_subnetwork(network string, name string, cidr string) *Stage {
	err := flociInsert(fmt.Sprintf("/compute/v1/projects/%s/regions/%s/subnetworks", s.project, flociRegion), map[string]any{
		"name":        name,
		"network":     "global/networks/" + network,
		"ipCidrRange": cidr,
	})
	require.NoError(s.t, err)
	return s
}

func (s *Stage) an_instance(zone string, name string, subnetwork string) *Stage {
	err := flociInsert(fmt.Sprintf("/compute/v1/projects/%s/zones/%s/instances", s.project, zone), map[string]any{
		"name":        name,
		"machineType": fmt.Sprintf("zones/%s/machineTypes/%s", zone, flociMachineType),
		"disks": []any{map[string]any{
			"boot":             true,
			"autoDelete":       true,
			"initializeParams": map[string]any{"sourceImage": flociBootImage},
		}},
		"networkInterfaces": []any{map[string]any{
			"subnetwork": fmt.Sprintf("regions/%s/subnetworks/%s", flociRegion, subnetwork),
		}},
	})
	require.NoError(s.t, err)
	return s
}

func (s *Stage) a_network_with_instances(instances map[string][]string) *Stage {
	s.a_network("net").and().a_subnetwork("net", "sub", "10.0.0.0/24")
	for zone, names := range instances {
		for _, name := range names {
			s.an_instance(zone, name, "sub")
		}
	}
	return s
}
