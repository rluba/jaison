# JSON serialization / deserialization module for Jai

*Attention: This version requires Jai beta 0.1.050! Please use [the 0.1.049 branch](https://github.com/rluba/jason/tree/release/beta_0.1.049) for older betas.*

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
success, result := json_parse_string(json_str, Your_Type_To_Parse_Into);
// … or if you want to get a generic structure back:
success, result := json_parse_string(json_str);
```

There are also a convenience functions for parsing if the JSON data is in a file:

```Jai
success, result := json_parse_file(json_filename, Your_Type_To_Parse_Into);
// … or 
success, result := json_parse_file(json_filename);
```


See [`typed.jai`](./typed.jai) and [`generic.jai`](./generic.jai) for details and additional options.

### Mixed typed and generic data

If you don’t know the structure of some subfield of your `Your_Type_To_Parse_Into` structure, but still want to get these values from the JSON data,
you can declare these fields as the generic type `JSON_Value` or `*JSON_Value` and the generic parse function will take over at that point:

```
Your_Type_To_Parse_Into :: struct {
	name: string;
	age: int;
	something_we_dont_know_much_about: *JSON_Value; // Whatever structure hides in the JSON, it will be parsed into JSON_Value.
}

## Printing / Serialization

Generating a string works the same for both interfaces:

```Jai
json_str := json_write_string(my_value);

```
where `my_value` is either a `JSON_Value` or any other data structure.

See [`module.jai`](./module.jai) for details and additional parameters.

## Dependencies

This module uses [the `unicode_utils` module](https://github.com/rluba/jai-unicode).
