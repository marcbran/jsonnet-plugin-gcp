local a = import 'arcourse-ui/main.libsonnet',
      gcp = import 'mixins.libsonnet',
      root = import 'root',
      call(ctx, method, params) = std.native('invoke:gcp')('call', [ctx, 'compute', method, params]);

local referenced = gcp.referenced {
  referenceService:: 'compute',
  referenceServicePath:: 'compute/v1/',
  referenceRoutes:: [
    { route: ['global', 'addresses', '$address'], template: ['global', 'addresses', '{address}'] },
    { route: ['global', 'firewalls', '$firewall'], template: ['global', 'firewalls', '{firewall}'] },
    { route: ['global', 'images', '$image'], template: ['global', 'images', '{image}'] },
    { route: ['global', 'networks', '$network'], template: ['global', 'networks', '{network}'] },
    { route: ['global', 'snapshots', '$snapshot'], template: ['global', 'snapshots', '{snapshot}'] },
    { route: ['regions', '$region'], template: ['regions', '{region}'] },
    { route: ['regions', '$region', 'addresses', '$address'], template: ['regions', '{region}', 'addresses', '{address}'] },
    { route: ['regions', '$region', 'resourcePolicies', '$resourcePolicy'], template: ['regions', '{region}', 'resourcePolicies', '{resourcePolicy}'] },
    { route: ['regions', '$region', 'subnetworks', '$subnetwork'], template: ['regions', '{region}', 'subnetworks', '{subnetwork}'] },
    { route: ['zones', '$zone'], template: ['zones', '{zone}'] },
    { route: ['zones', '$zone', 'disks', '$disk'], template: ['zones', '{zone}', 'disks', '{disk}'] },
    { route: ['zones', '$zone', 'instances', '$instance'], template: ['zones', '{zone}', 'instances', '{instance}'] },
    { route: ['zones', '$zone', 'machineTypes', '$machineType'], template: ['zones', '{zone}', 'machineTypes', '{machineType}'] },
  ],
};

[
  [['gcp', '$project'], {
    links+: {
      'Compute Engine': root.gcp.project($.project).compute,
    },
  }],
  [['gcp', '$project', 'compute']],
  [['gcp', '$project', 'compute', 'addresses'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'addresses',
    response:: call(
      self.ctx,
      'compute.addresses.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_region', label: 'Region', path: ['_region'], priority: 'secondary' },
        { key: 'address', kind: 'text', label: 'IP address', path: ['address'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'addressType', kind: 'text', label: 'Type', path: ['addressType'], priority: 'tertiary' },
        { key: 'purpose', kind: 'text', label: 'Purpose', path: ['purpose'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { param: 'region', path: ['_region'] }, { const: 'addresses' }, { param: 'address', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'disks'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'disks',
    response:: call(
      self.ctx,
      'compute.disks.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_zone', label: 'Zone', path: ['_zone'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'sizeGb', kind: 'number', label: 'Size (GB)', path: ['sizeGb'], priority: 'secondary' },
        { key: 'type', kind: 'text', label: 'Type', path: ['type'], priority: 'secondary', value:: gcp.ref(['type']) },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { param: 'zone', path: ['_zone'] }, { const: 'disks' }, { param: 'disk', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global']],
  [['gcp', '$project', 'compute', 'global', 'addresses'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.globalAddresses.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'address', kind: 'identifier', label: 'IP address', path: ['address'], priority: 'secondary' },
        { key: 'addressType', kind: 'text', label: 'Type', path: ['addressType'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'purpose', kind: 'text', label: 'Purpose', path: ['purpose'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'global' }, { const: 'addresses' }, { param: 'address', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global', 'addresses', '$address'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.globalAddresses.get',
      {
        address: $.address,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'global', 'firewalls'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.firewalls.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'direction', kind: 'text', label: 'Direction', path: ['direction'], priority: 'secondary' },
        { key: 'priority', kind: 'number', label: 'Priority', path: ['priority'], priority: 'secondary' },
        { key: 'disabled', kind: 'boolean', label: 'Disabled', path: ['disabled'], priority: 'secondary' },
        { key: 'network', kind: 'text', label: 'Network', path: ['network'], priority: 'tertiary', value:: gcp.ref(['network']) },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'global' }, { const: 'firewalls' }, { param: 'firewall', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global', 'firewalls', '$firewall'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.firewalls.get',
      {
        firewall: $.firewall,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'global', 'images'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.images.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'family', kind: 'text', label: 'Family', path: ['family'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'architecture', kind: 'text', label: 'Architecture', path: ['architecture'], priority: 'secondary' },
        { key: 'diskSizeGb', kind: 'number', label: 'Disk size (GB)', path: ['diskSizeGb'], priority: 'tertiary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'global' }, { const: 'images' }, { param: 'image', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global', 'images', '$image'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.images.get',
      {
        image: $.image,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'global', 'networks'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.networks.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'IPv4Range', kind: 'text', label: 'IPv4 range', path: ['IPv4Range'], priority: 'secondary' },
        { key: 'autoCreateSubnetworks', kind: 'boolean', label: 'Auto subnetworks', path: ['autoCreateSubnetworks'], priority: 'secondary' },
        { key: 'routingMode', kind: 'text', label: 'Routing mode', path: ['routingConfig', 'routingMode'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'global' }, { const: 'networks' }, { param: 'network', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global', 'networks', '$network'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.networks.get',
      {
        network: $.network,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'global', 'snapshots'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.snapshots.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'secondary' },
        { key: 'diskSizeGb', kind: 'number', label: 'Disk Size (GB)', path: ['diskSizeGb'], priority: 'secondary' },
        { key: 'storageBytes', kind: 'count', label: 'Storage (bytes)', path: ['storageBytes'], priority: 'tertiary' },
        { key: 'snapshotType', kind: 'text', label: 'Type', path: ['snapshotType'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'global' }, { const: 'snapshots' }, { param: 'snapshot', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'global', 'snapshots', '$snapshot'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.snapshots.get',
      {
        snapshot: $.snapshot,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'instances'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'instances',
    response:: call(
      self.ctx,
      'compute.instances.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_zone', label: 'Zone', path: ['_zone'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'machineType', kind: 'text', label: 'Machine type', path: ['machineType'], priority: 'secondary', value:: gcp.ref(['machineType']) },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { param: 'zone', path: ['_zone'] }, { const: 'instances' }, { param: 'instance', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'machineTypes'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'machineTypes',
    response:: call(
      self.ctx,
      'compute.machineTypes.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_zone', label: 'Zone', path: ['_zone'], priority: 'secondary' },
        { key: 'guestCpus', kind: 'count', label: 'vCPUs', path: ['guestCpus'], priority: 'secondary' },
        { key: 'memoryMb', kind: 'number', label: 'Memory (MB)', path: ['memoryMb'], priority: 'secondary' },
        { key: 'architecture', kind: 'text', label: 'Architecture', path: ['architecture'], priority: 'secondary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { param: 'zone', path: ['_zone'] }, { const: 'machineTypes' }, { param: 'machineType', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'regions'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.regions.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Region', path: ['name'], priority: 'primary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'secondary' },
        { key: 'deprecatedState', kind: 'status', label: 'Deprecation', path: ['deprecated', 'state'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { param: 'region', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'regions', '$region'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.regions.get',
      {
        region: $.region,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'addresses'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.addresses.list',
      self.page {
        region: $.region,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'address', kind: 'text', label: 'IP address', path: ['address'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'addressType', kind: 'text', label: 'Type', path: ['addressType'], priority: 'tertiary' },
        { key: 'purpose', kind: 'text', label: 'Purpose', path: ['purpose'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { origin: 'region' }, { const: 'addresses' }, { param: 'address', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'addresses', '$address'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.addresses.get',
      {
        region: $.region,
        address: $.address,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'resourcePolicies'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.resourcePolicies.list',
      self.page {
        region: $.region,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { origin: 'region' }, { const: 'resourcePolicies' }, { param: 'resourcePolicy', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'resourcePolicies', '$resourcePolicy'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.resourcePolicies.get',
      {
        region: $.region,
        resourcePolicy: $.resourcePolicy,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'subnetworks'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.subnetworks.list',
      self.page {
        region: $.region,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
        views: std.get($._params, 'views', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'ipCidrRange', kind: 'text', label: 'IPv4 range', path: ['ipCidrRange'], priority: 'secondary' },
        { key: 'network', kind: 'identifier', label: 'Network', path: ['network'], priority: 'secondary', value:: gcp.ref(['network']) },
        { key: 'purpose', kind: 'text', label: 'Purpose', path: ['purpose'], priority: 'tertiary' },
        { key: 'state', kind: 'status', label: 'State', path: ['state'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { origin: 'region' }, { const: 'subnetworks' }, { param: 'subnetwork', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'views', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'regions', '$region', 'subnetworks', '$subnetwork'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.subnetworks.get',
      {
        region: $.region,
        subnetwork: $.subnetwork,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'resourcePolicies'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'resourcePolicies',
    response:: call(
      self.ctx,
      'compute.resourcePolicies.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_region', label: 'Region', path: ['_region'], priority: 'secondary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { param: 'region', path: ['_region'] }, { const: 'resourcePolicies' }, { param: 'resourcePolicy', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'subnetworks'], a.table.node + gcp.project + gcp.paginated + gcp.aggregated + {
    itemsKey:: 'subnetworks',
    response:: call(
      self.ctx,
      'compute.subnetworks.aggregatedList',
      self.page {
        filter: std.get($._params, 'filter', null),
        includeAllScopes: std.get($._params, 'includeAllScopes', null),
        orderBy: std.get($._params, 'orderBy', null),
        serviceProjectNumber: std.get($._params, 'serviceProjectNumber', null),
        views: std.get($._params, 'views', null),
      }
    ),
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: '_region', label: 'Region', path: ['_region'], priority: 'secondary' },
        { key: 'ipCidrRange', kind: 'text', label: 'IPv4 range', path: ['ipCidrRange'], priority: 'secondary' },
        { key: 'network', kind: 'identifier', label: 'Network', path: ['network'], priority: 'secondary', value:: gcp.ref(['network']) },
        { key: 'purpose', kind: 'text', label: 'Purpose', path: ['purpose'], priority: 'tertiary' },
        { key: 'state', kind: 'status', label: 'State', path: ['state'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'regions' }, { param: 'region', path: ['_region'] }, { const: 'subnetworks' }, { param: 'subnetwork', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeAllScopes', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
      { default: null, name: 'serviceProjectNumber', type: 'string' },
      { default: null, name: 'views', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'zones'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.zones.list',
      self.page {
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'region', kind: 'identifier', label: 'Region', path: ['region'], priority: 'secondary', value:: gcp.ref(['region']) },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
        { key: 'supportsPzs', kind: 'boolean', label: 'Supports PZS', path: ['supportsPzs'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { param: 'zone', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.zones.get',
      {
        zone: $.zone,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'disks'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.disks.list',
      self.page {
        zone: $.zone,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'sizeGb', kind: 'number', label: 'Size (GB)', path: ['sizeGb'], priority: 'secondary' },
        { key: 'type', kind: 'text', label: 'Type', path: ['type'], priority: 'secondary', value:: gcp.ref(['type']) },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { origin: 'zone' }, { const: 'disks' }, { param: 'disk', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'disks', '$disk'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.disks.get',
      {
        zone: $.zone,
        disk: $.disk,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'instances'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.instances.list',
      self.page {
        zone: $.zone,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'status', kind: 'status', label: 'Status', path: ['status'], priority: 'secondary' },
        { key: 'machineType', kind: 'text', label: 'Machine type', path: ['machineType'], priority: 'secondary', value:: gcp.ref(['machineType']) },
        { key: 'creationTimestamp', kind: 'timestamp', label: 'Created', path: ['creationTimestamp'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { origin: 'zone' }, { const: 'instances' }, { param: 'instance', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'instances', '$instance'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.instances.get',
      {
        zone: $.zone,
        instance: $.instance,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'machineTypes'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'compute.machineTypes.list',
      self.page {
        zone: $.zone,
        filter: std.get($._params, 'filter', null),
        orderBy: std.get($._params, 'orderBy', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'guestCpus', kind: 'count', label: 'vCPUs', path: ['guestCpus'], priority: 'secondary' },
        { key: 'memoryMb', kind: 'number', label: 'Memory (MB)', path: ['memoryMb'], priority: 'secondary' },
        { key: 'architecture', kind: 'text', label: 'Architecture', path: ['architecture'], priority: 'secondary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'compute' }, { const: 'zones' }, { origin: 'zone' }, { const: 'machineTypes' }, { param: 'machineType', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'orderBy', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'compute', 'zones', '$zone', 'machineTypes', '$machineType'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'compute.machineTypes.get',
      {
        zone: $.zone,
        machineType: $.machineType,
      }
    ),
    data: self.response,
  }],
]
