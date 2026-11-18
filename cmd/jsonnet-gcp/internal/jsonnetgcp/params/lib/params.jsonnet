function(model, resources, paramsInference)
  [
    {
      method: item.method,
      params: [{ name: param.name, role: param.role } for param in item.params],
    }
    for item in std.sort(paramsInference, function(item) item.method)
  ]
