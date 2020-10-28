# JSON serialization / deserialization module for Jai

This module offers two interfaces:
* one uses a "generic tree" built from `JSON_Value` 
* the other is a typed version that serializes / deserializes your custom data structures.

The generic `JSON_Value` graphs are a pain to consume and even worse to produce by hand.
But they allow you to parse any JSON, even if you don’t know the structure (or can’t reproduce it in Jai because it varies).

The typed interface is what you want for most cases.

## Parsing / Deserialization

Parsing is as simple as:

```Jai
// Typed version:
result, success := json_parse_string(json_str, Your_Type_To_Parse_Into);
// … or if you want to get a generic structure back:
result, success := json_parse_string(json_str);
```

There are also a convenience functions if the JSON data is in a file:

```Jai
result, success := json_parse_file(json_filename, Your_Type_To_Parse_Into);
// … or 
result := json_parse_file(json_filename);
```

See [`typed.jai`](./typed.jai) and [`generic.jai`](./generic.jai) for details and additional options.

## Printing / Serialization

Generating a string works the same for both interfaces:

```Jai
json_str := json_write_string(my_value);

```
where `my_value` is either a `JSON_Value` or any other data structure.

See [`module.jai`](./module.jai) for details and additional parameters.
