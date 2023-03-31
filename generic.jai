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
	union {
		boolean: bool;
		number: float64;
		str: string;
		array: [] JSON_Value;
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
			free(str);
		case .ARRAY;
			for array {
				json_free(it);
			}
			array_free(array);
		case .OBJECT;
			for object {
				free(it_index);
				json_free(it);
			}
			deinit(object);

			free(object);
	}
}

json_parse_file :: (filename: string) -> success: bool, JSON_Value {
    file_data, success := read_entire_file(filename);
	result: JSON_Value;
	if !success		{
		log_error("Could not read file");
		return false, result;
	}
	defer free(file_data);

	if context.log_level >= .VERBOSE log("Read file: %", success);
	success, result = json_parse_string(file_data);
	return success, result;
}

json_parse_string :: (content: string) -> success: bool, JSON_Value {
    if !content then return false, .{};

	result, remainder, success := parse_value(content);
	if !success		return false, result;

	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder.count {
		log_error("Unexpected trailing characters: %", remainder);
		return false, result;
	}

	return true, result;
}

// For debug purposes
print_val :: (using val: JSON_Value) {
	if #complete type == {
		case .NULL;
			print("null");
		case .BOOLEAN;
			print("%", boolean);
		case .NUMBER;
			print("%", number);
		case .STRING;
			print("\"%\"", str);
		case .ARRAY;
			print("[");
			for array	print_val(it);
			print("]");
		case .OBJECT;
			print("%", <<object);
	}
}

json_value :: (str: string) -> JSON_Value {
	val: JSON_Value;
	val.type =.STRING;
	val.str = str;
	return val;
}

json_value :: (obj: *JSON_Object) -> JSON_Value {
	val: JSON_Value;
	val.type =.OBJECT;
	val.object = obj;
	return val;
}

json_set_null :: (val: *JSON_Value) {
	val.type = .NULL;
}

json_set :: (val: *JSON_Value, value: bool) {
	val.type = .BOOLEAN;
	val.boolean = value;
}

json_set :: (val: *JSON_Value, value: int) {
	val.type = .NUMBER;
	val.number = cast(float64) value;
}

json_set :: (val: *JSON_Value, value: float64) {
	val.type = .NUMBER;
	val.number = value;
}

json_set :: (val: *JSON_Value, value: string) {
	val.type = .STRING;
	val.str = value;
}

json_set :: (val: *JSON_Value, value: [] JSON_Value) {
	val.type = .ARRAY;
	val.array = value;
}

json_set :: (val: *JSON_Value, value: *JSON_Object) {
	val.type = .OBJECT;
	val.object = value;
}

json_write_json_value :: (builder: *String_Builder, using val: JSON_Value, indent_char := "\t", level := 0) {
	if #complete type == {
		case JSON_Type.NULL;
			append(builder, "null");
		case JSON_Type.BOOLEAN;
			append(builder, ifx boolean "true" else "false");
		case JSON_Type.NUMBER;
			print_item_to_builder(builder, number);
		case JSON_Type.STRING;
			json_append_escaped(builder, str);
		case JSON_Type.ARRAY;
			append(builder, "[");
			for array {
				if indent_char.count {
					append(builder, "\n");
					for 0..level	append(builder, indent_char);
				}
				json_write_json_value(builder, it, indent_char, level + 1);
				if it_index != array.count - 1	append(builder, ",");
			}
			if indent_char.count {
				append(builder, "\n");
				for 0..level-1	append(builder, indent_char);
			}
			append(builder, "]");
		case JSON_Type.OBJECT;
			append(builder, "{");
			obj := object;
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
				v, found := table_find(obj, it);
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
	dotpos := find_index_from_left(path, #char ".");
	if dotpos == -1 {
		table_set(obj, path, val);
		return true;
	}

	next := slice(path, 0, dotpos);
	remainder := advance(path, dotpos + 1);
	if !next.count		return false;
	if !remainder.count	return false;

	next_value, success := table_find(obj, next);
	next_obj: *JSON_Object;
	if success {
		if next_value.type != JSON_Type.OBJECT	return false;
		next_obj = xx next_value.object;
	} else {
		next_obj = cast(*JSON_Object) alloc(size_of(JSON_Object));
		memset(next_obj, 0, size_of(JSON_Object));
		next_value = json_value(next_obj);
		table_add(obj, next, next_value);
	}

	return json_set(next_obj, remainder, val);
}

get_as :: (val: JSON_Value, $T: Type) -> T {
	#insert #run () -> string {
		if T == bool {
			return #string END
				assert(val.type == .BOOLEAN, "Expected a % but got %", T, val.type);
				return val.boolean;
			END;
		} else if T == float || T == float64 {
			return #string END
				assert(val.type == .NUMBER, "Expected a % but got %", T, val.type);
				return cast(T) val.number;
			END;
		} else if T == string {
			return #string END
				assert(val.type == .STRING, "Expected a % but got %", T, val.type);
				return val.str;
			END;
		} else if T == [] JSON_Value {
			return #string END
				assert(val.type == .ARRAY, "Expected a % but got %", T, val.type);
				return val.array;
			END;
		} else if T == JSON_Object {
			return #string END
				assert(val.type == .OBJECT, "Expected a % but got %", T, val.type);
				return <<val.object;
			END;
		} else {
			compiler_report("Unsupported type");
			return "";
		}
	}();
}

#scope_module

parse_value :: (to_parse: string) -> JSON_Value, remainder: string, success: bool {
	result: JSON_Value;
	remainder := trim_left(to_parse, WHITESPACE_CHARS);
	success := false;
	if remainder[0] == {
		case #char "n";
			remainder, success = expect_and_slice(remainder, "null");
			if !success		return result, remainder, false;
			json_set_null(*result);
			result.type = JSON_Type.NULL;
			return result, remainder, true;
		case #char "t";
			remainder, success = expect_and_slice(remainder, "true");
			if !success		return result, remainder, false;
			json_set(*result, true);
			return result, remainder, true;
		case #char "f";
			remainder, success = expect_and_slice(remainder, "false");
			if !success		return result, remainder, false;
			json_set(*result, false);
			return result, remainder, true;
		case #char "\"";
			str: string;
			str, remainder, success = parse_string(remainder);
			json_set(*result, str);
		case #char "[";
			result.type = JSON_Type.ARRAY;
			result.array, remainder, success = parse_array(remainder);
		case #char "{";
			obj := cast(*JSON_Object) alloc(size_of(JSON_Object));
			<<obj, remainder, success = parse_object(remainder);
			result = json_value(obj);
		case;
			result.type = JSON_Type.NUMBER;
			result.number, success, remainder = string_to_float64(remainder);
	}

	return result, remainder, success;
}

parse_array:: (str: string) -> result: [] JSON_Value, remainder: string, success: bool {
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

		existing := table_find_pointer(*result, key);
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



#import "Compiler";
#import "unicode_utils";
