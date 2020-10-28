// Generic JSON parsing/writing functions. Result is always a JSON_Value,
// which is awful to read and even more awful to create for complex structures.
// But it’s useful for some cases where re-creating the whole JSON structure as
// custom Jai struct types is inconvenient or not possible.

// This generic interface was the very first part I wrote in Jai and hasn’t been thorougly tested.
// Tread with care. There may be dragons.

JSON_Type :: enum u8 {
	NULL :: 0;
	BOOLEAN :: 1;
	NUMBER :: 3;
	STRING :: 2;
	ARRAY :: 5;
	OBJECT :: 4;
}

JSON_Value :: struct {
	type: JSON_Type;
	value: union {
		boolean: bool;
		number: float64;
		str: string;
		array: [..] JSON_Value;
		object: *JSON_Object;
	};
}

JSON_Object :: Table(string, JSON_Value);

json_free :: (using val: JSON_Value) {
	if #complete type == {
		case .NULL;
		case .BOOLEAN;
		case .NUMBER;

		case .STRING;
			free(value.str);
		case .ARRAY;
			for value.array {
				json_free(it);
			}
			array_free(value.array);
		case .OBJECT;
			for value.object {
				free(it_index);
				json_free(it);
			}
			uninit(value.object);

			free(value.object);
	}
}

json_parse_file :: (filename: string) -> JSON_Value, success: bool {
    file_data, success := read_entire_file(filename);
	result: JSON_Value;
	if !success		{
		report_error("Couldn’t read file");
		return result, false;
	}
	defer free(file_data);

	log(Log_Mode.VERBOSE, "Read file: %", success);
	result, success = json_parse_string(file_data);
	return result, success;
}

json_parse_string :: (content: string) -> JSON_Value, success: bool {
	result, remainder, success := parse_value(content);
	if !success		return result, false;

	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder.count {
		report_error("Unexpected trailing characters: %", remainder);
		return result, false;
	}

	return result, true;
}

// For debug purposes
print_val :: (using val: JSON_Value) {
	if #complete type == {
		case .NULL;
			log(.VERBOSE, "null");
		case .BOOLEAN;
			log(.VERBOSE, "%", value.boolean);
		case .NUMBER;
			log(.VERBOSE, "%", value.number);
		case .STRING;
			log(.VERBOSE, "\"%\"", value.str);
		case .ARRAY;
			log(.VERBOSE, "[");
			for value.array	print_val(it);
			log(.VERBOSE, "]");
		case .OBJECT;
			log(.VERBOSE, "%", <<value.object);
	}
}

json_value :: (str: string) -> JSON_Value {
	val: JSON_Value;
	val.type = JSON_Type.STRING;
	val.value.str = str;
	return val;
}

json_value :: (obj: *JSON_Object) -> JSON_Value {
	val: JSON_Value;
	val.type = JSON_Type.OBJECT;
	val.value.object = obj;
	return val;
}

json_write_json_value :: (builder: *String_Builder, using val: JSON_Value, indent_char := "\t", level := 0) {
	if #complete type == {
		case JSON_Type.NULL;
			append(builder, "null");
		case JSON_Type.BOOLEAN;
			append(builder, ifx value.boolean "true" else "false");
		case JSON_Type.NUMBER;
			print_item_to_builder(builder, value.number);
		case JSON_Type.STRING;
			json_append_escaped(builder, value.str);
		case JSON_Type.ARRAY;
			append(builder, "[");
			for value.array {
				if indent_char.count {
					append(builder, "\n");
					for 0..level	append(builder, indent_char);
				}
				json_write_json_value(builder, it, indent_char, level + 1);
				if it_index != value.array.count - 1	append(builder, ",");
			}
			if indent_char.count {
				append(builder, "\n");
				for 0..level-1	append(builder, indent_char);
			}
			append(builder, "]");
		case JSON_Type.OBJECT;
			append(builder, "{");
			obj := value.object;
			keys: [..] string;
			defer array_free(keys);
			array_reserve(*keys, obj.count);
			for v, k: <<obj {
				array_add(*keys, k);
			}
			intro_sort(keys, compare);
			for keys {
				if indent_char.count {
					append(builder, "\n");
					for 0..level	append(builder, indent_char);
				}
				json_append_escaped(builder, it);
				append(builder, ": ");
				v, found := table_find(<<obj, it);
				assert(found, "Missing table value %", it);
				json_write_json_value(builder, v, indent_char, level + 1);
				if it_index != obj.count - 1	append(builder, ",");
			}
			if indent_char.count {
				append(builder, "\n");
				for 0..level-1	append(builder, indent_char);
			}
			append(builder, "}");
	}
}

json_set :: (obj: *JSON_Object, path: string, val: JSON_Value) -> bool {
	dotpos, found := index_of_char(path, #char ".");
	if !found {
		table_set(obj, path, val);
		return true;
	}

	next := slice(path, 0, dotpos);
	remainder := advance(path, dotpos + 1);
	if !next.count		return false;
	if !remainder.count	return false;

	next_value, success := table_find(<<obj, next);
	next_obj: *JSON_Object;
	if success {
		if next_value.type != JSON_Type.OBJECT	return false;
		next_obj = xx next_value.value.object;
	} else {
		next_obj = cast(*JSON_Object) alloc(size_of(JSON_Object));
		memset(next_obj, 0, size_of(JSON_Object));
		next_value = json_value(next_obj);
		table_add(obj, next, next_value);
	}

	return json_set(next_obj, remainder, val);
}

#scope_file

parse_value :: (to_parse: string) -> JSON_Value, remainder: string, success: bool {
	result: JSON_Value;
	remainder := trim_left(to_parse, WHITESPACE_CHARS);
	success := false;
	if remainder[0] == {
		case #char "n";
			remainder, success = expect_and_slice(remainder, "null");
			if !success		return result, remainder, false;
			result.type = JSON_Type.NULL;
			return result, remainder, true;
		case #char "t";
			remainder, success = expect_and_slice(remainder, "true");
			if !success		return result, remainder, false;
			result.type = JSON_Type.BOOLEAN;
			result.value.boolean = true;
			return result, remainder, true;
		case #char "f";
			remainder, success = expect_and_slice(remainder, "false");
			if !success		return result, remainder, false;
			result.type = JSON_Type.BOOLEAN;
			return result, remainder, true;
		case #char "\"";
			str: string;
			str, remainder, success = parse_string(remainder);
			result = json_value(str);
		case #char "[";
			result.type = JSON_Type.ARRAY;
			result.value.array, remainder, success = parse_array(remainder);
		case #char "{";
			obj := cast(*JSON_Object) alloc(size_of(JSON_Object));
			<<obj, remainder, success = parse_object(remainder);
			result = json_value(obj);
		case;
			result.type = JSON_Type.NUMBER;
			result.value.number, success, remainder = string_to_float64(remainder);
	}

	return result, remainder, success;
}

parse_array:: (str: string) -> result: [..] JSON_Value, remainder: string, success: bool {
	assert(str[0] == #char "[", "Invalid object start %", str);
	remainder := advance(str);
	result: [..] JSON_Value;
	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder[0] == #char "]" {
		remainder = advance(remainder);
		return result, remainder, true;
	}

	while true {
		value: JSON_Value;
		success: bool;
		value, remainder, success = parse_value(remainder);
		if !success	return result, remainder, false;

		array_add(*result, value);

		remainder = trim_left(remainder, WHITESPACE_CHARS);
		if remainder[0] != #char ","	break;
		remainder = advance(remainder);
		remainder = trim_left(remainder, WHITESPACE_CHARS);
	}

	if remainder[0] != #char "]"	return result, remainder, false;
	remainder = advance(remainder);
	return result, remainder, true;
}

parse_object :: (str: string) -> result: JSON_Object, remainder: string, success: bool {
	assert(str[0] == #char "{", "Invalid object start %", str);
	remainder := advance(str);
	result: JSON_Object;
	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder[0] == #char "}" {
		remainder = advance(remainder);
		return result, remainder, true;
	}

	init(*result, 32);
	while true {
		if remainder[0] != #char "\""	return result, remainder, false;

		key: string;
		value: JSON_Value;
		success: bool;
		key, remainder, success = parse_string(remainder);
		if !success	return result, remainder, false;

		existing := table_find_pointer(result, key);
		if existing		return result, remainder, false;

		remainder = trim_left(remainder, WHITESPACE_CHARS);
		if remainder[0] != #char ":"	return result, remainder, false;
		remainder = advance(remainder);
		remainder = trim_left(remainder, WHITESPACE_CHARS);
		value, remainder, success = parse_value(remainder);
		if !success	return result, remainder, false;

		table_add(*result, key, value);

		remainder = trim_left(remainder, WHITESPACE_CHARS);
		if remainder[0] != #char ","	break;
		remainder = advance(remainder);
		remainder = trim_left(remainder, WHITESPACE_CHARS);
	}

	if remainder[0] != #char "}"	return result, remainder, false;
	remainder = advance(remainder);
	return result, remainder, true;
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

