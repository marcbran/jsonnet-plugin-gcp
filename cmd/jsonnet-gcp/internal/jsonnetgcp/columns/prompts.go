package columns

const columnsPrompt = `Read input.json.

Choose useful table-view columns for the items of the Google Cloud list method in "method". "array" is where the items sit in the response, "itemSchema" describes one item.

Return only JSON matching the provided schema.

Rules:
- Choose roughly 3 to 6 columns.
- Column paths must be property paths relative to the list item, for example ["name"] or ["scheduling", "preemptible"].
- If itemSchema is a scalar value rather than an object, return a single column with path [] to show the item itself.
- Do not invent properties that are not supported by itemSchema.
- Prefer names, statuses, locations, timestamps, small counts, and concise scalar fields.
- Operators recognize Google Cloud resources by name. Make "name" primary when it exists; keep numeric "id" only when it is what operators copy around.
- Avoid selfLink, URLs to other resources, fingerprints, descriptions, nested arrays, and large object values unless they are clearly useful as table columns. A reference to another resource is useful only when it is the main thing operators look for, such as an instance's machine type.
- Use priority "primary" for the main identifying column, "secondary" for generally useful columns and "tertiary" for lower-value columns.
- Use kind values that describe display intent, such as "identifier", "name", "status", "timestamp", "count", "text", "number", or "boolean".
- Keep labels short and human-readable.
`
