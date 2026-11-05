local jsonnetMainLib = import 'jsonnet/main.libsonnet';

local j = jsonnetMainLib;

local le(indent) = j.Fodder.LineEnd(0, indent);

local prettyArray(elements, indent) =
  j.Array([
    element.fodder(le(indent + 2))
    for element in elements
  ]).closeFodder(le(indent));

local prettyObject(fields, indent) =
  j.Object([
    field { fodder: [le(indent + 2)] }
    for field in fields
  ]).closeFodder(le(indent));

local prettyApply(target, args, indent) =
  j.Apply(target, [
    arg.fodder(le(indent + 2))
    for arg in args
  ]).rightFodder(le(indent));

local isAsciiLetter(c) = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');

local isAsciiDigit(c) = c >= '0' && c <= '9';

local jsonnetKeywords = ['assert', 'else', 'error', 'false', 'for', 'function', 'if', 'import', 'importstr', 'in', 'local', 'null', 'self', 'super', 'tailstrict', 'then', 'true'];

local isUnquotedFieldName(s) =
  std.length(s) > 0 &&
  (s[0] == '_' || isAsciiLetter(s[0])) &&
  std.all([c == '_' || isAsciiLetter(c) || isAsciiDigit(c) for c in std.stringChars(s)]) &&
  !std.member(jsonnetKeywords, s);

local objectField(name, expr) =
  if isUnquotedFieldName(name) then j.Field(name, expr) else j.Field(j.String(name), expr);

local hiddenField(name, expr) = objectField(name, expr) { Hide: 0 };

local access(expr, name) =
  if isUnquotedFieldName(name) then j.Member(expr, name) else j.Index(expr, j.String(name));

local literal(value) =
  if value == null then j.Null
  else if std.type(value) == 'string' then j.String(value)
  else if std.type(value) == 'boolean' then if value then j.True else j.False
  else if std.type(value) == 'number' then j.Number(std.toString(value))
  else if std.type(value) == 'array' then j.Array([literal(item) for item in value])
  else if std.type(value) == 'object' then j.Object([objectField(f, literal(value[f])) for f in std.objectFields(value)])
  else error 'unsupported literal type: ' + std.type(value);

local view(name) = j.Member(j.Member(j.Var('a'), name), 'node');

local mixin(name) = j.Member(j.Var('gcp'), name);

local adds(exprs) = std.foldl(function(acc, e) j.Add(acc, e), exprs[1:], exprs[0]);

local selfMember(name) = j.Member(j.Self, name);

local paramValue(name) =
  j.Std.get(access(j.Dollar, '_params'), j.String(name)).default(j.Null);

local isRouteVar(seg) = std.startsWith(seg, '$');

{
  service:: error 'generate requires a service',
  tree:: error 'generate requires a tree',
  manifest:: true,

  local g = self,

  local base = ['gcp', '$project'],
  local servicePath = base + [g.service],
  local baseLinks = [{ const: 'gcp' }, { origin: 'project' }, { const: g.service }],

  local routeLinks(route) = [
    if isRouteVar(seg) then { origin: seg[1:] } else { const: seg }
    for seg in route
  ],

  local paramsExpr(vars, params, paginated) =
    local fields =
      [objectField(v, access(j.Dollar, v)) for v in vars] +
      [objectField(p.name, paramValue(p.name)) for p in params];
    local obj = if std.length(fields) == 0 then j.Object([]) else prettyObject(fields, 4);
    if paginated then
      if std.length(fields) == 0 then selfMember('page') else j.Add(selfMember('page'), obj)
    else obj,

  local callExpr(method, params) =
    prettyApply(j.Var('call'), [selfMember('ctx'), j.String(method), params], 4),

  local paramSpecsFields(params) =
    if std.length(params) == 0 then []
    else [
      objectField('_paramSpecs', prettyArray([
        literal({ name: p.name, type: p.type, default: null })
        for p in params
      ], 4)) { SuperSugar: true },
    ],

  local linkSpecsField(specs) =
    if std.length(specs) == 0 then []
    else [
      hiddenField('linkSpecs', prettyArray([
        prettyObject([
          objectField('at', literal(spec.at)),
          objectField('keys', literal(spec.keys)),
          objectField('value', literal(spec.value)),
        ], 4)
        for spec in specs
      ], 2)),
    ],

  local columnExpr(col) =
    local plain = { [k]: col[k] for k in std.objectFields(col) if k != 'reference' };
    if !std.get(col, 'reference', false) then literal(plain)
    else j.Object(
      [objectField(k, literal(plain[k])) for k in std.objectFields(plain)] +
      [hiddenField('value', j.Apply(mixin('ref'), [literal(col.path)]))]
    ),

  local withoutScope(columns, vars) = [col for col in columns if !std.member([[v] for v in vars], col.path)],

  local tableField(at, columns) =
    hiddenField('table', prettyObject([
      objectField('at', literal(at)),
      objectField('columns', prettyArray([columnExpr(col) for col in columns], 4)),
    ], 2)),

  local pathExpr(path) = j.Array([j.String(p) for p in path]),

  local entry(path, node) =
    if node == null then j.Array([pathExpr(path)])
    else j.Array([pathExpr(path), node]),

  local rowLink(c, at, extra) =
    if c.detail == null then []
    else [{
      at: at,
      keys: [{ path: [c.detail.field] }],
      value: baseLinks + extra + [{ param: c.detail.param, path: [c.detail.field] }],
    }],

  local collectionNode(c) =
    local bases = [view('table'), mixin('project')] + (if c.paginated then [mixin('paginated')] else []);
    adds(bases + [prettyObject(
      [
        hiddenField('response', callExpr(c.method, paramsExpr(c.vars, c.params, c.paginated))),
        hiddenField('data', selfMember('response')),
        tableField([c.items], withoutScope(c.columns, c.vars)),
      ] +
      linkSpecsField(rowLink(c, [c.items], routeLinks(c.route))) +
      paramSpecsFields(c.params),
      0
    )]),

  local scopeColumns(c) = [
    { key: '_' + v, label: std.asciiUpper(v[0]) + v[1:], path: ['_' + v], priority: 'secondary' }
    for v in c.vars
  ],

  local withScopeColumns(columns, scope) =
    if std.length(columns) == 0 then scope
    else [columns[0]] + scope + columns[1:],

  local aggregatedNode(c) =
    local agg = c.aggregated;
    local bases = [view('table'), mixin('project')] + (if agg.paginated then [mixin('paginated')] else []) + [mixin('aggregated')];
    local extra = [
      if isRouteVar(seg) then { param: seg[1:], path: ['_' + seg[1:]] } else { const: seg }
      for seg in c.route
    ];
    local link =
      if c.detail == null then []
      else [{
        at: ['items'],
        keys: [{ path: ['_scope'] }, { path: [c.detail.field] }],
        value: baseLinks + extra + [{ param: c.detail.param, path: [c.detail.field] }],
      }];
    adds(bases + [prettyObject(
      [
        hiddenField('itemsKey', literal(agg.itemsKey)),
        hiddenField('response', callExpr(agg.method, paramsExpr([], agg.params, agg.paginated))),
        tableField(['items'], withScopeColumns(withoutScope(c.columns, c.vars), scopeColumns(c))),
      ] +
      linkSpecsField(link) +
      paramSpecsFields(agg.params),
      0
    )]),

  local detailNode(c) =
    adds([view('resource'), mixin('project'), j.Var('referenced'), prettyObject([
      hiddenField('response', callExpr(c.detail.method, paramsExpr(c.vars + [c.detail.param], [], false))),
      objectField('data', selfMember('response')),
    ], 0)]),

  local nodes = std.flattenArrays([
    [{ path: servicePath + c.route, node: collectionNode(c) }] +
    (if c.detail == null then [] else [{ path: servicePath + c.detail.route, node: detailNode(c) }]) +
    (if c.aggregated == null then [] else [{ path: servicePath + c.aggregated.route, node: aggregatedNode(c) }])
    for c in g.tree.collections
  ]),

  local key(path) = std.join('/', path),

  local nodePaths = std.set([key(n.path) for n in nodes]),

  local prefixes(path) = [path[:i] for i in std.range(std.length(servicePath) + 1, std.length(path) - 1)],

  local intermediates = std.set(
    [
      p
      for n in nodes
      for p in prefixes(n.path)
      if !std.member(nodePaths, key(p))
    ],
    key
  ),

  local sorted = std.sort(
    [{ path: p, node: null } for p in intermediates] + nodes,
    function(n) key(n.path)
  ),

  local rootExpr(path) =
    std.foldl(
      function(acc, seg)
        if isRouteVar(seg) then j.Apply(access(acc, seg[1:]), [access(j.Dollar, seg[1:])])
        else access(acc, seg),
      path,
      j.Var('root')
    ),

  local serviceLink =
    entry(base, prettyObject([
      objectField('links', prettyObject([
        objectField(g.tree.service.title, rootExpr(servicePath)),
      ], 2)) { SuperSugar: true },
    ], 0)),

  local body = prettyArray(
    [serviceLink, entry(servicePath, null)] +
    [entry(n.path, n.node) for n in sorted],
    0
  ),

  local referenceRoutes = [
    { template: c.detail.template, route: c.detail.route }
    for c in g.tree.collections
    if c.detail != null
  ],

  local referencedBind =
    j.LocalBind('referenced', j.Add(mixin('referenced'), prettyObject([
      hiddenField('referenceService', literal(g.service)),
      hiddenField('referenceServicePath', literal(g.tree.service.servicePath)),
      hiddenField('referenceRoutes', prettyArray([
        literal(r)
        for r in referenceRoutes
      ], 2)),
    ], 0))),

  local generated = j.Local([
    j.LocalBind('a', j.Import('arcourse-ui/main.libsonnet')),
    j.LocalBind('gcp', j.Import('mixins.libsonnet')).varFodder(le(0)),
    j.LocalBind('root', j.Import('root')).varFodder(le(0)),
    j.LocalFunctionBind(
      'call',
      [j.Parameter('ctx'), j.Parameter('method'), j.Parameter('params')],
      j.Apply(j.Apply(j.Member(j.Var('std'), 'native'), [j.String('invoke:gcp')]), [
        j.String('call'),
        j.Array([j.Var('ctx'), j.String(g.service), j.Var('method'), j.Var('params')]),
      ])
    ).varFodder(le(0)),
  ], if std.length(referenceRoutes) == 0 then body.fodder(j.Fodder.LineEnd(1, 0))
  else j.Local([referencedBind], body.fodder(j.Fodder.LineEnd(1, 0))).fodder(j.Fodder.LineEnd(1, 0))),

  jsonnet: if g.manifest then j.manifestJsonnet(generated) else generated,
}
