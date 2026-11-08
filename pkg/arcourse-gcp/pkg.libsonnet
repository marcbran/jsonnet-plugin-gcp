local p = import 'pkg/main.libsonnet';

p.pkg({
  source: 'https://github.com/marcbran/jsonnet-plugin-gcp/tree/main/pkg/arcourse-gcp',
  repo: 'https://github.com/marcbran/jsonnet.git',
  branch: 'arcourse/gcp/arcourse-gcp',
  path: 'arcourse/gcp/arcourse-gcp',
  target: 'arcourse-gcp',
  external: ['root'],
}, |||
  Arcourse entry nodes for Google Cloud: the `gcp` node listing the configured projects and the
  `gcp/$project` nodes. APIs come from the `arcourse-gcp-<api>` packages, which link themselves
  from the project nodes.
|||, {
  projects: p.desc(|||
    Projects to browse, as `{ [projectId]: { name } }`; none by default.
  |||),
  nodeList: p.desc(|||
    The `gcp` and `gcp/$project` nodes for the configured projects.
  |||),
})
