package params

const paramsPrompt = `Read input.json.

Classify every query parameter of the Google Cloud list method in "method" by the role it plays when listing items. "params" lists the parameters with their type, enum values and description.

Return only JSON matching the provided schema.

Roles:
- "filter": narrows which items are returned, for example a filter expression, a name or object prefix, a glob, an offset range, or a flag that includes or excludes a category of items such as soft-deleted objects or old versions.
- "shaping": changes what each item or the response contains without changing which items are returned, for example a projection, a delimiter that groups results into prefixes, or a flag that adds extra entries to the response.
- "pagination": controls which page is returned or how many items it holds, for example page tokens and page sizes.
- "sort": controls the order of the items.
- "other": anything that fits none of the above, for example a billing project, a partial-success switch, or a request option that doesn't affect the listed items.

Rules:
- Classify every parameter in params exactly once, using its name as given.
- Use the description, type, and enum values, not only the name.
- When a parameter both narrows and reshapes the response, prefer "filter".
- Keep reasons short.
`
