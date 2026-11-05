local a = import 'arcourse-ui/main.libsonnet',
      gcp = import 'mixins.libsonnet',
      root = import 'root',
      call(ctx, method, params) = std.native('invoke:gcp')('call', [ctx, 'storage', method, params]);

local referenced = gcp.referenced {
  referenceService:: 'storage',
  referenceServicePath:: 'storage/v1/',
  referenceRoutes:: [
    { route: ['buckets', '$bucket'], template: ['b', '{bucket}'] },
    { route: ['buckets', '$bucket', 'objects', '$object'], template: ['b', '{bucket}', 'o', '{object}'] },
  ],
};

[
  [['gcp', '$project'], {
    links+: {
      'Cloud Storage': root.gcp.project($.project).storage,
    },
  }],
  [['gcp', '$project', 'storage']],
  [['gcp', '$project', 'storage', 'buckets'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'storage.buckets.list',
      self.page {
        prefix: std.get($._params, 'prefix', null),
        projection: std.get($._params, 'projection', null),
        returnPartialSuccess: std.get($._params, 'returnPartialSuccess', null),
        softDeleted: std.get($._params, 'softDeleted', null),
        userProject: std.get($._params, 'userProject', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'location', kind: 'text', label: 'Location', path: ['location'], priority: 'secondary' },
        { key: 'storageClass', kind: 'text', label: 'Storage class', path: ['storageClass'], priority: 'secondary' },
        { key: 'timeCreated', kind: 'timestamp', label: 'Created', path: ['timeCreated'], priority: 'tertiary' },
        { key: 'versioning.enabled', kind: 'boolean', label: 'Versioning', path: ['versioning', 'enabled'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'storage' }, { const: 'buckets' }, { param: 'bucket', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'prefix', type: 'string' },
      { default: null, name: 'projection', type: 'string' },
      { default: null, name: 'returnPartialSuccess', type: 'string' },
      { default: null, name: 'softDeleted', type: 'string' },
      { default: null, name: 'userProject', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'storage', 'buckets', '$bucket'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'storage.buckets.get',
      {
        bucket: $.bucket,
      }
    ),
    data: self.response,
  }],
  [['gcp', '$project', 'storage', 'buckets', '$bucket', 'objects'], a.table.node + gcp.project + gcp.paginated + {
    response:: call(
      self.ctx,
      'storage.objects.list',
      self.page {
        bucket: $.bucket,
        delimiter: std.get($._params, 'delimiter', null),
        endOffset: std.get($._params, 'endOffset', null),
        filter: std.get($._params, 'filter', null),
        includeFoldersAsPrefixes: std.get($._params, 'includeFoldersAsPrefixes', null),
        includeTrailingDelimiter: std.get($._params, 'includeTrailingDelimiter', null),
        matchGlob: std.get($._params, 'matchGlob', null),
        prefix: std.get($._params, 'prefix', null),
        projection: std.get($._params, 'projection', null),
        softDeleted: std.get($._params, 'softDeleted', null),
        startOffset: std.get($._params, 'startOffset', null),
        userProject: std.get($._params, 'userProject', null),
        versions: std.get($._params, 'versions', null),
      }
    ),
    data:: self.response,
    table:: {
      at: ['items'],
      columns: [
        { key: 'name', kind: 'name', label: 'Name', path: ['name'], priority: 'primary' },
        { key: 'size', kind: 'number', label: 'Size', path: ['size'], priority: 'secondary' },
        { key: 'storageClass', kind: 'text', label: 'Storage class', path: ['storageClass'], priority: 'secondary' },
        { key: 'updated', kind: 'timestamp', label: 'Updated', path: ['updated'], priority: 'secondary' },
        { key: 'contentType', kind: 'text', label: 'Content type', path: ['contentType'], priority: 'tertiary' },
      ],
    },
    linkSpecs:: [
      {
        at: ['items'],
        keys: [{ path: ['name'] }],
        value: [{ const: 'gcp' }, { origin: 'project' }, { const: 'storage' }, { const: 'buckets' }, { origin: 'bucket' }, { const: 'objects' }, { param: 'object', path: ['name'] }],
      },
    ],
    _paramSpecs+: [
      { default: null, name: 'delimiter', type: 'string' },
      { default: null, name: 'endOffset', type: 'string' },
      { default: null, name: 'filter', type: 'string' },
      { default: null, name: 'includeFoldersAsPrefixes', type: 'string' },
      { default: null, name: 'includeTrailingDelimiter', type: 'string' },
      { default: null, name: 'matchGlob', type: 'string' },
      { default: null, name: 'prefix', type: 'string' },
      { default: null, name: 'projection', type: 'string' },
      { default: null, name: 'softDeleted', type: 'string' },
      { default: null, name: 'startOffset', type: 'string' },
      { default: null, name: 'userProject', type: 'string' },
      { default: null, name: 'versions', type: 'string' },
    ],
  }],
  [['gcp', '$project', 'storage', 'buckets', '$bucket', 'objects', '$object'], a.resource.node + gcp.project + referenced + {
    response:: call(
      self.ctx,
      'storage.objects.get',
      {
        bucket: $.bucket,
        object: $.object,
      }
    ),
    data: self.response,
  }],
]
