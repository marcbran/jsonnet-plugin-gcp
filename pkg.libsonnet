local p = import 'pkg/main.libsonnet';

p.pkg({
  source: 'https://github.com/marcbran/jsonnet-plugin-gcp',
  repo: 'https://github.com/marcbran/jsonnet.git',
  branch: 'plugin/gcp',
  path: 'plugin/gcp',
  target: 'gcp',
}, |||
  Read-only calls against Google Cloud APIs, driven by the services' Discovery documents. Services and credentials are configured when the plugin is started or embedded in Go.
|||, {
  call: p.desc(|||
    Calls a read method (HTTP `GET`, not denied). `ctx` is `{ project }`, `service` is the Discovery API name (e.g. `compute`),
    `method` is the Discovery method id (e.g. `compute.instances.list`) and `params` its parameters by Discovery name.
    `project` is taken from `ctx` wherever the method declares it and must not be passed in `params`. Null parameters are
    omitted. Pagination tokens and page sizes are ordinary parameters and response fields.

    On success returns the decoded response body. On failure returns a `Status` object (`kind: "Status"`).
  |||),
})
