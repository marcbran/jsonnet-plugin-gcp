local root = import 'root';

local project = {
  ctx:: { project: $.project },
};

local paginated = {
  inputToken:: 'pageToken',
  outputToken:: 'nextPageToken',
  pageSize:: 'maxResults',
  _paramSpecs+: [
    { name: name, type: if name == $.pageSize then 'number' else 'string', default: null }
    for name in [$.pageSize, $.inputToken]
  ],
  page:: {
    [name]: std.get($._params, name, null)
    for name in [$.pageSize, $.inputToken]
  },
  links+: {
    pagination:
      local params = std.get($, '_params', {});
      local next = std.get($.response, $.outputToken, null);
      (if std.get(params, $.inputToken, null) == null then {} else { first: $ { _params: params { [$.inputToken]: null } } })
      + (if next == null then {} else { next: $ { _params: params { [$.inputToken]: next } } }),
  },
};

local scopeFields(scope) =
  local parts = std.split(scope, '/');
  if std.length(parts) != 2 then { _scope: scope }
  else { _scope: parts[1], ['_' + std.rstripChars(parts[0], 's')]: parts[1] };

local aggregated = {
  itemsKey:: error 'aggregated requires an itemsKey',
  response:: error 'aggregated requires a response',
  data:: {
    local scopes = std.get($.response, 'items', {}),
    items: [
      item + scopeFields(scope)
      for scope in std.objectFields(scopes)
      for item in std.get(scopes[scope], $.itemsKey, [])
    ],
  },
};

local ref(path) = function(item)
  local value = std.foldl(function(acc, key) if std.type(acc) == 'object' then std.get(acc, key, null) else null, path, item);
  if std.type(value) == 'string' && std.startsWith(value, 'https://') then
    local segments = std.split(value, '/');
    segments[std.length(segments) - 1]
  else value;

local referenceFieldsSkipped = ['selfLink', 'selfLinkWithId'];

local urlStrings(value, path) =
  if std.type(value) == 'string' then
    if std.startsWith(value, 'https://') then [{ path: path, url: value }] else []
  else if std.type(value) == 'array' then
    std.flattenArrays([urlStrings(value[i], path + [std.toString(i)]) for i in std.range(0, std.length(value) - 1)])
  else if std.type(value) == 'object' then
    std.flattenArrays([
      urlStrings(value[k], path + [k])
      for k in std.objectFields(value)
      if !std.member(referenceFieldsSkipped, k)
    ])
  else [];

local isTemplateVar(seg) = std.startsWith(seg, '{') && std.endsWith(seg, '}');

local matchTemplate(template, segments) =
  if std.length(template) != std.length(segments) then null
  else std.foldl(
    function(acc, i)
      if acc == null then null
      else if isTemplateVar(template[i]) then acc { [std.substr(template[i], 1, std.length(template[i]) - 2)]: segments[i] }
      else if template[i] == segments[i] then acc
      else null,
    std.range(0, std.length(template) - 1),
    {}
  );

local referencedNode(service, routes, project, rest) =
  local matches = [
    { route: r.route, vars: vars }
    for r in routes
    for vars in [matchTemplate(r.template, rest)]
    if vars != null
  ];
  if std.length(matches) == 0 then null
  else std.foldl(
    function(acc, seg)
      if std.startsWith(seg, '$') then acc[seg[1:]](matches[0].vars[seg[1:]])
      else acc[seg],
    matches[0].route,
    root.gcp.project(project)[service]
  );

local resolveReference(service, servicePath, routes, project, url) =
  local marker = '/' + servicePath;
  local found = std.findSubstr(marker, url);
  if std.length(found) == 0 then null
  else
    local start = found[0] + std.length(marker);
    local segments = std.split(std.substr(url, start, std.length(url) - start), '/');
    if std.length(segments) >= 2 && segments[0] == 'projects' then referencedNode(service, routes, segments[1], segments[2:])
    else referencedNode(service, routes, project, segments);

local referenced = {
  referenceService:: error 'referenced requires a referenceService',
  referenceServicePath:: error 'referenced requires a referenceServicePath',
  referenceRoutes:: [],
  links+: {
    [std.join('/', ref.path)]: node
    for ref in urlStrings(std.get($, 'data', null), [])
    for node in [resolveReference($.referenceService, $.referenceServicePath, $.referenceRoutes, $.project, ref.url)]
    if node != null
  },
};

{
  project: project,
  paginated: paginated,
  aggregated: aggregated,
  ref: ref,
  referenced: referenced,
}
