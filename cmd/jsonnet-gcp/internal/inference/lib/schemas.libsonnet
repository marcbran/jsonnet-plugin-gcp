local scalarTypes = ['string', 'boolean', 'integer', 'number', 'any'];

local schema(model, s, depth) =
  if s == null then { type: 'any' }
  else if std.objectHas(s, '$ref') then
    if depth <= 0 then { type: 'object' }
    else schema(model, std.get(model.schemas, s['$ref'], null), depth - 1)
  else
    local type = std.get(s, 'type', 'any');
    if type == 'array' then { type: 'array', items: schema(model, std.get(s, 'items', null), depth) }
    else if type == 'object' && std.objectHas(s, 'properties') then
      if depth <= 0 then { type: 'object' }
      else {
        type: 'object',
        properties: {
          [p]: schema(model, s.properties[p], depth - 1)
          for p in std.objectFields(s.properties)
        },
      }
    else if type == 'object' && std.objectHas(s, 'additionalProperties') then
      { type: 'object', additionalProperties: schema(model, s.additionalProperties, depth - 1) }
    else { type: type } + (if std.objectHas(s, 'enum') then { enum: s.enum } else {}) + (if std.objectHas(s, 'format') then { format: s.format } else {});

local isScalar(s) = std.member(scalarTypes, s.type);

local at(s, path) =
  if std.length(path) == 0 then { schema: s, crossedArray: false }
  else
    local next = std.get(std.get(s, 'properties', {}), path[0], null);
    if next == null then { schema: null, crossedArray: false }
    else if next.type == 'array' then
      local rest = at(next.items, path[1:]);
      rest { crossedArray: true }
    else at(next, path[1:]);

{
  schema(model, ref, depth=3):: schema(model, { '$ref': ref }, depth + 1),
  isScalar:: isScalar,
  at:: at,
}
