// This file contains just the JSON serialization functions. See generic.jai and typed.jai for parse fuctions.

// Generates a JSON string from either a JSON_Value or any custom type.
// "indent_char" does what it says on the tin.
// "ignore" is only used for custom types to determine which properties of your custom type should be serialized.
//		The default ignore function ignores all struct members that have the note @JsonIgnore.
// "rename" is used for renaming certain members.
//      It gets called with the Type_Info_Struct_Member and must return the new name of the field.
// 		The default procedure rename members by their @JsonName note. Eg: @JsonName(renamed_member).
json_write_string :: (value: $T, indent_char := "\t", ignore := ignore_by_note, rename := rename_by_note) -> string {
	builder: String_Builder;
	defer free_buffers(*builder);
	json_append_value(*builder, value, indent_char, ignore, rename);
	return builder_to_string(*builder);
}

json_write_file :: (filename: string, value: $T, indent_char := "\t", ignore := ignore_by_note, rename := rename_by_note) -> bool {
	builder: String_Builder;
	defer free_buffers(*builder);
	json_append_value(*builder, value, indent_char, ignore, rename);
	return write_entire_file(filename, *builder);
}

json_append_value :: (builder: *String_Builder, val: $T, indent_char := "\t", ignore := ignore_by_note, rename := rename_by_note) {
	#if T == JSON_Value {
		json_write_json_value(builder, val, indent_char);
	} else {
		info := type_info(T);
		json_write_native(builder, *val, info, indent_char, ignore, rename);
	}
}

// This function is useful if you have a JSON template string and just want to
// safely insert a value without having to replicate the full json structure in Jai.
// The return value does NOT include quotes around the string.
//
// Example:
// JSON_TEMPLATE :: #string END
// {
// 	"complicated": {
// 		"json": {
// 			"structure": {
// 				"for_a_stupid_api": {
// 					"that_needs": [
// 						{"a_deeply_nested_value": "%1"}
// 					]
// 				}
// 			}
// 		}
// 	}
// }
// END
// escaped_value := json_escape_string(my_unsafe_value);
// defer free(escaped_value);
// json_str := print(JSON_TEMPLATE, escaped_value);
json_escape_string :: (str: string) -> string {
	builder: String_Builder;
	defer	free_buffers(*builder);
	json_append_escaped(*builder, str);
	escaped := builder_to_string(*builder);
	return escaped;
}

Ignore_Proc :: #type (member: *Type_Info_Struct_Member) -> bool;
Rename_Proc :: #type (member: *Type_Info_Struct_Member) -> string;

ignore_by_note :: (member: *Type_Info_Struct_Member) -> bool {
	for note: member.notes {
		if note == "JsonIgnore"	return true;
	}
	return false;
}

rename_by_note :: (member: *Type_Info_Struct_Member) -> string {
	for note: member.notes {
		if !begins_with(note, "JsonName(") continue;
        if note.count <= 10 || note[note.count-1] != #char ")" {
            log_error("Invalid JsonName note format. Expected a name in parenthesis, but the note was \"%\".", note);
            continue;
        }

		return slice(note, 9, note.count-10);
	}

	return member.name;
}

#scope_module

WHITESPACE_CHARS :: " \t\n\r";

#load "generic.jai";
#load "typed.jai";

json_append_escaped :: (builder: *String_Builder, str: string) {
	remaining := str;
	next_pos := index_of_illegal_string_char(remaining);
	append(builder, "\"");
	while (next_pos >= 0) {
		append(builder, slice(remaining, 0, next_pos));
		if remaining[next_pos] == {
			case #char "\\";
				append(builder,  "\\\\");
			case #char "\"";
				append(builder,  "\\\"");
			case #char "\n";
				append(builder, "\\n");
			case #char "\r";
				append(builder, "\\r");
			case #char "\t";
				append(builder, "\\t");
			case;
				// ToDo: handle illegal multi-byte characters
				// print("Escaping: %\n\n", slice(remaining, next_pos, remaining.count - next_pos));
				print_to_builder(builder, "\\u%", formatInt(remaining[next_pos], base=16, minimum_digits=4));
		}
		remaining = advance(remaining, next_pos + 1);
		next_pos = index_of_illegal_string_char(remaining);
	}
	append(builder, remaining);
	append(builder, "\"");
}

index_of_illegal_string_char :: (str: string) -> s64 {
	for 0..str.count - 1 {
		if str[it] == #char "\\" || str[it] == #char "\"" || str[it] <= 0x1F {
			return it;
		}
	}
	return -1;
}

expect_and_slice :: (str: string, expected: string) -> remainder: string, success: bool {
	if str.count < expected.count || !equal(slice(str, 0, expected.count), expected) {
		log_error("Unexpected token. Expected \"%\" but got: %", expected, str);
		return str, false;
	}
	remainder := advance(str, expected.count);
	return remainder, true;
}

parse_string :: (str: string) -> result: string, remainder: string, success: bool {
	assert(str[0] == #char "\"", "Invalid string start %", str);
	inside := advance(str);
	needsUnescape := false;
	while inside[0] != #char "\"" {
		if inside.count < 2 	return "", str, false;
		if inside[0] == #char "\\" {
			needsUnescape = true;
			if inside.count < 2	return "", str, false;
			advance(*inside);
		}
		advance(*inside);
	}

	length := inside.data - str.data - 1;
	result := slice(str, 1, length);
	if needsUnescape {
		success: bool;
		result, success = unescape(result);
		if !success		return "", str, false;
	} else {
		result = copy_string(result);
	}

	remainder := slice(str, length + 2, str.count - length - 2);
	return result, remainder, true;
}

unescape :: (str: string) -> result: string, success: bool {
	result := alloc_string(str.count);
	rc := 0;
	for i: 0..str.count-1 {
		if str[i] != #char "\\" {
			// Check for invalid characters for JSON
			if str[i] < 0x20	return "", false;

			result[rc] = str[i];
			rc += 1;
		} else {
			if i == str.count - 1	return "", false;
			i += 1;
			if str[i] == {
				case #char "\""; #through;
				case #char "/"; #through;
				case #char "\\";
					result[rc] = str[i];
					rc += 1;
				case #char "b";
					result[rc] = 0x08;
					rc += 1;
				case #char "f";
					result[rc] = 0x0c;
					rc += 1;
				case #char "n";
					result[rc] = #char "\n";
					rc += 1;
				case #char "r";
					result[rc] = #char "\r";
					rc += 1;
				case #char "t";
					result[rc] = #char "\t";
					rc += 1;
				case #char "u";
					if i + 4 >= str.count	return "", false;
					unicode_char, success := parse_unicode(slice(str, i + 1, 4));
					if !success		return "", false;
					utf8_len := encode_utf8(unicode_char, *(result.data[rc]));
					rc += utf8_len;
					i += 4;
				case;
					return "", false;
			}
		}
	}
	result.count = rc;
	return result, true;
}

#import "Basic";
#import "File";
#import "String";

#import "Hash_Table";
#import "unicode_utils";
#import "IntroSort";

