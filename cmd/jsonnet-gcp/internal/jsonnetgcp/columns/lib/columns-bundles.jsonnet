local schemas = import 'schemas.libsonnet';
local treeLib = import 'tree.libsonnet';

function(model, resources)
  local tree = treeLib {
    model:: model,
    overrides:: resources,
  };
  {
    [c.method]: {
      'input.json': std.manifestJsonEx({
        method: c.method,
        path: std.join('/', c.route),
        array: [c.items],
        itemSchema: schemas.schema(model, c.itemRef, 3),
      }, '  '),
    }
    for c in tree.collections
    if c.itemRef != null
  }
