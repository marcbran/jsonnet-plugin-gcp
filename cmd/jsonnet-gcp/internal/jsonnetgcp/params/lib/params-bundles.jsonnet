local treeLib = import 'tree.libsonnet';

local summary(text) =
  local plain = std.join(' ', [word for word in std.split(std.strReplace(text, '\n', ' '), ' ') if word != '']);
  if std.length(plain) <= 400 then plain else std.substr(plain, 0, 400) + '…';

local paramEntry(param) = {
  name: param.name,
  type: param.type,
} + {
  [field]: param[field]
  for field in ['items', 'enum']
  if std.objectHas(param, field)
} + (
  if std.objectHas(param, 'description') then { description: summary(param.description) } else {}
);

local bundle(method, route, params) = {
  'input.json': std.manifestJsonEx({
    method: method,
    path: std.join('/', route),
    params: [paramEntry(param) for param in params],
  }, '  '),
};

function(model, resources)
  local tree = treeLib {
    model:: model,
    overrides:: resources,
  };
  {
    [c.method]: bundle(c.method, c.route, c.params)
    for c in tree.collections
    if std.length(c.params) > 0
  } + {
    [c.aggregated.method]: bundle(c.aggregated.method, c.aggregated.route, c.aggregated.params)
    for c in tree.collections
    if c.aggregated != null && std.length(c.aggregated.params) > 0
  }
