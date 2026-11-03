local projectParam = 'project';
local pageToken = 'pageToken';
local nextPageToken = 'nextPageToken';
local pageSize = 'maxResults';
local maxColumns = 5;
local preferredColumns = ['status', 'state', 'location', 'type', 'storageClass', 'sizeGb', 'size', 'creationTimestamp', 'timeCreated', 'updated'];

local isVar(seg) = std.startsWith(seg, '{') && std.endsWith(seg, '}');
local varName(seg) = std.substr(seg, 1, std.length(seg) - 2);

local label(name) =
  local chars = std.stringChars(name);
  local spaced = std.join('', [
    if i > 0 && chars[i] >= 'A' && chars[i] <= 'Z' then ' ' + std.asciiLower(chars[i]) else chars[i]
    for i in std.range(0, std.length(chars) - 1)
  ]);
  std.asciiUpper(spaced[0]) + spaced[1:];

{
  model:: error 'tree requires a model',
  overrides:: {},
  columns:: [],

  local t = self,
  local methods = t.model.methods,
  local schemas = t.model.schemas,
  local renames = std.get(t.overrides, 'segments', {}),
  local include = std.get(t.overrides, 'include', []),

  local templateSegments(path) =
    local segs = std.split(path, '/');
    if std.length(segs) >= 2 && segs[0] == 'projects' && segs[1] == '{' + projectParam + '}' then segs[2:] else segs,

  local route(path) = [
    if isVar(seg) then '$' + varName(seg) else std.get(renames, seg, seg)
    for seg in templateSegments(path)
  ],

  local checkPath(m) =
    if std.length(std.findSubstr('{+', m.path)) > 0 || std.length(std.findSubstr(':', m.path)) > 0 then
      error 'method %s has a path template the generator does not support: %s' % [m.id, m.path]
    else m,

  local method(id) =
    if std.objectHas(methods, id) then checkPath(methods[id])
    else error 'resources.json includes %s, which is not a readable method of %s' % [id, t.model.name],

  local sibling(m, name) =
    local found = [
      methods[id]
      for id in std.objectFields(methods)
      if methods[id].resource == m.resource && methods[id].name == name
    ];
    if std.length(found) == 0 then null else checkPath(found[0]),

  local properties(ref) = std.get(std.get(schemas, ref, {}), 'properties', {}),

  local arrayProperty(ref, exclude=[]) =
    local props = properties(ref);
    local arrays = [p for p in std.objectFields(props) if std.get(props[p], 'type', null) == 'array' && !std.member(exclude, p)];
    if std.objectHas(props, 'items') && std.get(props.items, 'type', null) == 'array' then 'items'
    else if std.length(arrays) > 0 then arrays[0]
    else null,

  local itemRef(listRef, items) =
    local prop = std.get(properties(listRef), items, {});
    std.get(std.get(prop, 'items', {}), '$ref', null),

  local scopedItemsKey(aggregatedRef) =
    local scoped = std.get(std.get(std.get(properties(aggregatedRef), 'items', {}), 'additionalProperties', {}), '$ref', null);
    if scoped == null then null else arrayProperty(scoped, ['warning']),

  local paramType(p) = if std.member(['integer', 'number'], p.type) then 'number' else 'string',

  local queryParams(m) = [
    { name: name, type: paramType(m.parameters[name]) }
    for name in std.objectFields(m.parameters)
    if m.parameters[name].location == 'query'
    if !std.member([projectParam, pageToken, pageSize], name)
  ],

  local paginated(m) =
    std.objectHas(m.parameters, pageToken) &&
    std.objectHas(properties(std.get(m, 'response', '')), nextPageToken),

  local pathVars(path) = [varName(seg) for seg in templateSegments(path) if isVar(seg)],

  local idField(ref) =
    local props = properties(ref);
    if std.objectHas(props, 'name') then 'name'
    else if std.objectHas(props, 'id') then 'id'
    else null,

  local defaultColumns(ref) =
    local props = properties(ref);
    local id = idField(ref);
    local scalar(p) = std.member(['string', 'integer', 'number', 'boolean'], std.get(props[p], 'type', null)) && !std.objectHas(props[p], '$ref');
    local rest = [p for p in preferredColumns if std.objectHas(props, p) && scalar(p) && p != id];
    (if id == null then [] else [{ key: id, label: label(id), path: [id], priority: 'primary' }]) +
    [{ key: p, label: label(p), path: [p], priority: 'secondary' } for p in rest[:std.min(maxColumns - 1, std.length(rest))]],

  local propertyAt(ref, path) =
    if ref == null || std.length(path) == 0 then null
    else
      local prop = std.get(properties(ref), path[0], null);
      if prop == null then null
      else if std.length(path) == 1 then prop
      else propertyAt(std.get(prop, '$ref', null), path[1:]),

  local isReference(ref, path) =
    local prop = propertyAt(ref, path);
    prop != null && std.get(prop, 'x-reference', false),

  local columnsFor(m, ref) =
    local explicit = [entry.columns for entry in t.columns if entry.method == m.id && std.length(entry.columns) > 0];
    local columns = if std.length(explicit) > 0 then explicit[0] else defaultColumns(ref);
    [
      col + (if isReference(ref, col.path) then { reference: true } else {})
      for col in columns
    ],

  local collection(id) =
    local m = method(id);
    local items = arrayProperty(std.get(m, 'response', ''));
    local ref = itemRef(std.get(m, 'response', ''), items);
    local get = sibling(m, 'get');
    local detail =
      if get == null then null
      else
        local vars = pathVars(get.path);
        local listVars = pathVars(m.path);
        if std.length(vars) != std.length(listVars) + 1 || vars[:std.length(listVars)] != listVars then null
        else { method: get.id, param: vars[std.length(vars) - 1], template: templateSegments(get.path), route: route(get.path), field: idField(ref) };
    local agg = sibling(m, 'aggregatedList');
    local aggregated =
      if agg == null then null
      else
        local key = scopedItemsKey(std.get(agg, 'response', ''));
        if key == null then null
        else {
          method: agg.id,
          route: [seg for seg in route(agg.path) if seg != 'aggregated'],
          itemsKey: key,
          params: queryParams(agg),
          paginated: paginated(agg),
        };
    local columns = columnsFor(m, ref);
    {
      method: m.id,
      route: route(m.path),
      vars: [v for v in pathVars(m.path) if v != projectParam],
      items: items,
      itemRef: ref,
      params: queryParams(m),
      paginated: paginated(m),
      detail: if detail == null || detail.field == null then null else detail,
      aggregated: aggregated,
      columns: columns,
    },

  service: {
    name: t.model.name,
    servicePath: t.model.servicePath,
    title: std.get(t.overrides, 'title', std.strReplace(t.model.title, ' API', '')),
  },
  collections: std.sort([collection(id) for id in include], function(c) std.join('/', c.route)),
}
