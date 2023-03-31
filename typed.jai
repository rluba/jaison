
// Parse a JSON string into the given Type.
// All members of Type that are not present in the JSON are kept at their default values.
// All fields in the JSON that have no corresponding member in Type are ignored by default
// but you can pass ignore_unknown = false to fail instead.
//@Incomplete: The typed interface cannot yet parse into float members. (Because I haven’t needed it yet. 🙈) PRs welcome!
json_parse_string :: (content: string, $T: Type, ignore_unknown := true, rename := rename_by_note) -> success: bool, T {
	result: T;
	if !content then return false, result;

	info := type_info(T);
	remainder, success := parse_value(content, cast(*u8)*result, info, ignore_unknown, "", rename=rename);
	if !success		return false, result;

	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder.count {
		log_error("Unexpected trailing characters: %", remainder);
		return false, result;
	}

	return true, result;
}

json_parse_file :: (filename: string, $T: Type, ignore_unknown := true, rename := rename_by_note) -> success: bool, T {
	file_data, success := read_entire_file(filename);
	result: T;
	if !success		{
		log_error("Could not read file: %", filename);
		return false, result;
	}
	defer free(file_data);

	if (context.log_level >= .VERBOSE) {
		log("Read file: %", success);
	}
	success, result = json_parse_string(file_data, T, ignore_unknown, rename=rename);
	return success, result;
}

json_write_native :: (builder: *String_Builder, data: *void, info: *Type_Info, indent_char := "\t", ignore := ignore_by_note, rename := rename_by_note, level := 0) {
	if info.type == {
		case .BOOL;
			append(builder, ifx <<(cast(*bool) data) "true" else "false");
		case .INTEGER; #through;
		case .FLOAT;
			any_val: Any;
			any_val.type = info;
			any_val.value_pointer = data;
			print_item_to_builder(builder, any_val);
		case .ENUM;
			any_val: Any;
			any_val.type = info;
			any_val.value_pointer = data;

			append(builder, #char "\"");
			print_item_to_builder(builder, any_val);
			append(builder, #char "\"");
		case .STRING;
			json_append_escaped(builder, <<(cast(*string) data));
		case .ARRAY;
			info_array := cast(*Type_Info_Array) info;
			element_size := info_array.element_type.runtime_size;
			assert(element_size != -1);  // @Robustness @Incomplete: Right now, this might fail.

			stride := get_array_stride(element_size);
			array_data := data;
			array_count := info_array.array_count;
			if info_array.array_count == -1 {
				array_count = << cast(*s64) data;

				array_dest: **void = data + 8;
				array_data = << array_dest;
			}

			append(builder, "[");
			if array_data {
				if indent_char.count {
					append(builder, "\n");
					for 0..level	append(builder, indent_char);
				}
				for 0..array_count-1 {
					json_write_native(builder, array_data, info_array.element_type, indent_char, ignore, rename, level + 1);
					if it != array_count - 1		append(builder, ",");
					array_data += stride;
				}
			}
			if indent_char.count {
				append(builder, "\n");
				for 0..level-1	append(builder, indent_char);
			}
			append(builder, "]");
		case .STRUCT;
			struct_info := cast(*Type_Info_Struct) info;
			if is_generic_json_value(info) {
				value := cast(*JSON_Value) data;
				json_write_json_value(builder, <<value, indent_char, level);
			} else {
				append(builder, #char "{");
				first := true;
				json_write_native_members(builder, data, struct_info.members, indent_char, ignore, rename, level, *first);
				if indent_char.count {
					append(builder, "\n");
					for 0..level-1	append(builder, indent_char);
				}
				append(builder, "}");
			}
		case .POINTER;
			ptr_info := cast(*Type_Info_Pointer) info;
			ptr := << cast(**void) data;
			if ptr {
				json_write_native(builder, ptr, ptr_info.pointer_to, indent_char, ignore, rename, level);
			} else {
				append(builder, "null");
			}
		case;
			assert(false, "Unsupported type: %", info.type);
	}
}

#scope_file

json_write_native_members :: (builder: *String_Builder, data: *void, members: [] Type_Info_Struct_Member, indent_char := "\t", ignore := ignore_by_note, rename: Rename_Proc, level := 0, first: *bool) {
	for * member: members {
		if member.flags & .CONSTANT     continue;
		if ignore(member)               continue;
		if (member.type.type == .STRUCT && member.flags & .USING) {
			info := cast(*Type_Info_Struct) member.type;
			json_write_native_members(builder, data + member.offset_in_bytes, info.members, indent_char, ignore, rename, level, first);
		} else {
			if !<<first	append(builder, ",");
			<<first = false;

			if indent_char.count {
				append(builder, "\n");
				for 0..level	append(builder, indent_char);
			}

			renamed_name := rename(member);
			name := ifx renamed_name.count > 0	renamed_name else member.name;

			json_append_escaped(builder, name);
			append(builder, ": ");
			json_write_native(builder, data + member.offset_in_bytes, member.type, indent_char, ignore, rename, level + 1);
		}
	}
}

get_array_stride :: (size: s64) -> s64 {
    return size; // @Incomplete: Is this always correct?
}

is_generic_json_value_or_pointer_to_it :: (info: *Type_Info) -> bool {
	value_info := info;
	if info.type == .POINTER {
		pointer_info := cast(*Type_Info_Pointer) info;
		value_info = pointer_info.pointer_to;
	}

	return is_generic_json_value(info);
}

is_generic_json_value :: (info: *Type_Info) -> bool {
	return info == type_info(JSON_Value);
}

parse_value :: (to_parse: string, slot: *u8, info: *Type_Info, ignore_unknown: bool, field_name: string, rename: Rename_Proc) -> remainder: string, success: bool {
	remainder := trim_left(to_parse, WHITESPACE_CHARS);
	success := true;

	prepare_slot :: (expected_type: Type_Info_Tag, info: *Type_Info, slot: *u8, to_parse: string) -> *u8, success: bool, is_generic: bool, info: *Type_Info {
		value_info := info;
		if info.type == .POINTER {
			pointer_info := cast(*Type_Info_Pointer) info;
			value_info = pointer_info.pointer_to;
		}

        if info.type == .ENUM {
            info_enum := cast(*Type_Info_Enum)info;
            value_info = info_enum.internal_type;
        }

		is_generic := is_generic_json_value(value_info);

		if value_info.type != expected_type {
			teaser := to_parse;
			if teaser.count > 50	teaser.count = 50;
			log_error("Cannot parse % value into type %. Remaining input is: %…", expected_type, <<info, teaser);
			return null, false, false, value_info;
		}

		if info.type == .POINTER {
			value_slot := alloc(value_info.runtime_size);
			initializer: (*void);
			if value_info.type == .STRUCT {
				struct_info := cast(*Type_Info_Struct) value_info;
				initializer = struct_info.initializer;
			}
			if initializer {
				initializer(value_slot);
			} else {
				memset(value_slot, 0, value_info.runtime_size);
			}
			<<cast(**u8)slot = value_slot;
			return value_slot, true, is_generic, value_info;
		} else {
			return slot, true, is_generic, value_info;
		}
	}

	is_generic: bool;
	if remainder[0] == {
		case #char "n";
			remainder, success = expect_and_slice(remainder, "null");
			if !success		return remainder, false;
			if slot {
				// @ToDo, @Incomplete: Handle null properly
				if info.type != .POINTER {
					log_error("Got NULL value for non-pointer type % of field \"%\". Assigning default value instead.", <<info, field_name);
				}
			}
			return remainder, true;
		case #char "t";
			remainder, success = expect_and_slice(remainder, "true");
			if !success		return remainder, false;
			if slot {
				value_slot: *u8;
				value_slot, success, is_generic = prepare_slot(.BOOL, info, slot, to_parse);
				if success {
					if is_generic {
						json_set(cast(*JSON_Value)value_slot, true);
					} else {
						<<cast(*bool)value_slot = true;
					}
				}
			}
		case #char "f";
			remainder, success = expect_and_slice(remainder, "false");
			if !success		return remainder, false;
			if slot {
				value_slot: *u8;
				value_slot, success, is_generic = prepare_slot(.BOOL, info, slot, to_parse);
				if success {
					if is_generic {
						json_set(cast(*JSON_Value)value_slot, false);
					} else {
						<<cast(*bool)value_slot = false;
					}
				}
			}
		case #char "\"";
			if slot && info && info.type == .ENUM {
				info_enum := cast(*Type_Info_Enum)info;
				value_slot: *u8;
				value_slot, success, is_generic = prepare_slot(.INTEGER, info_enum.internal_type, slot, to_parse);
				remainder, success = parse_enum_string(remainder, value_slot, info_enum);
			} else {
				value: string;
				value, remainder, success = parse_string(remainder);
				stored := false;
				defer if !stored	free(value);
				if success && slot {
					value_slot: *u8;
					value_slot, success, is_generic = prepare_slot(.STRING, info, slot, to_parse);
					if success {
						if is_generic {
							json_set(cast(*JSON_Value)value_slot, value);
						} else {
							<<cast(*string)value_slot = value;
						}
						stored = true;
					}
				}
			}
		case #char "[";
			value_slot: *u8;
			value_info: *Type_Info;
			if slot {
				value_slot, success, is_generic, value_info = prepare_slot(.ARRAY, info, slot, to_parse);
			}
			if success {
				if is_generic {
					value: [] JSON_Value;
					value, remainder, success = parse_array(remainder);
					json_set(cast(*JSON_Value)value_slot, value);
				} else {
					remainder, success = parse_array(remainder, value_slot, cast(*Type_Info_Array) value_info, ignore_unknown, rename=rename);
				}
			}
		case #char "{";
			value_slot: *u8;
			value_info: *Type_Info;
			if slot {
				value_slot, success, is_generic, value_info = prepare_slot(.STRUCT, info, slot, to_parse);
			}
			if success {
				if is_generic {
					value := New(JSON_Object);
					<<value, remainder, success = parse_object(remainder);
					json_set(cast(*JSON_Value)value_slot, value);
				} else {
					remainder, success = parse_object(remainder, value_slot, cast(*Type_Info_Struct) value_info, ignore_unknown, rename=rename);
				}
			}
		case;
			if slot == null || info.type == .FLOAT || is_generic_json_value_or_pointer_to_it(info) {
				float_value: float64;
				float_value, success, remainder = string_to_float64(remainder);
				if success && slot {
					value_slot: *u8;
					value_info: *Type_Info;
					value_slot, success, is_generic, value_info = prepare_slot(.FLOAT, info, slot, to_parse);
					if success {
						if is_generic {
							json_set(cast(*JSON_Value)value_slot, float_value);
						} else {
							if value_info.runtime_size == 4 {
								(<< cast(*float) slot) = cast(float) float_value;
							} else {
								assert(value_info.runtime_size == 8);
								(<< cast(*float64) slot) = float_value;
							}
						}
					}
				}
			} else {
                if slot {
                    value_slot: *u8;
                    value_info: *Type_Info;
                    value_slot, success, is_generic, value_info = prepare_slot(.INTEGER, info, slot, to_parse);
                    if success {
                        if is_generic {
                            int_value: s64;
                            int_value, success, remainder = string_to_int(remainder, T = s64);
                            if success {
                                json_set(cast(*JSON_Value)value_slot, int_value);
                            } else {
                                log_error("Could not parse \"%\" as an integer.", to_parse);
                            }
                        } else {
                            info_int := cast(*Type_Info_Integer) value_info;
                            success, remainder = parse_and_write_integer(info_int, value_slot, to_parse);
                        }
                    }
                } else {
                    int_value: s64;
                    int_value, success, remainder = string_to_int(remainder, T = s64);
                    if !success {
                        log_error("Could not parse \"%\" as an integer.", to_parse);
                    }
                }
			}
	}

	return remainder, success;
}

parse_enum_string :: (str: string, slot: *u8, info_enum: *Type_Info_Enum) -> remainder: string, success: bool {
	value, remainder, success := parse_string(str);
	defer free(value);
    if !success return remainder, false;

    // Parse by members' names
    normalize_enum_value :: inline (name: string) -> string #expand {
        normalized := trim(name);
        // @Speed, @Cleanup: Why are we tprinting this every time? We could just use the name directly and then check for the dot.
        if starts_with(normalized, tprint("%.", info_enum.name))
            normalized = slice(normalized, info_enum.name.count+1, normalized.count-info_enum.name.count-1);
        if starts_with(normalized, ".")
            normalized = slice(normalized, 1, normalized.count-1);
        return normalized;
    }

    int_info := info_enum.internal_type;
    int_value: s64;
    if info_enum.enum_type_flags & .FLAGS {
        parsed_count := 0;
        values := split(value, "|");

        for v: values {
            name := normalize_enum_value(v);
            for info_enum.names {
                if name == it {
                    parsed_count += 1;
                    int_value |= info_enum.values[it_index];
                    break;
                }
            }
        }

        if parsed_count != values.count {
            success = false;
        }
    } else {
        success = false;
        name := normalize_enum_value(value);
        for info_enum.names {
            if name == it {
                int_value = info_enum.values[it_index];
                success = true;
                break;
            }
        }
    }

    if success {
        if int_info.signed {
            valid, low, high := Reflection.range_check_and_store(int_value, int_info, slot);
            if !valid {
                log_error("The value '%' is out of range. (It must be between % and %.)", int_value, low, high);
                return remainder, false;
            }
        } else {
            valid, low, high := Reflection.range_check_and_store(cast(u64) int_value, int_info, slot);
            if !valid {
                log_error("The value '%' is out of range. (It must be between % and %.)", int_value, low, high);
                return remainder, false;
            }
        }
    }

    return remainder, success;
}

parse_array :: (str: string, slot: *u8, info: *Type_Info_Array, ignore_unknown: bool, rename: Rename_Proc) -> remainder: string, success: bool {
	element_size: int;
	stride: int;
	if slot {
		assert(info.array_count == -1, "Fixed array are not implemented yet");

		element_size = info.element_type.runtime_size;
		assert(element_size != -1, "Unknown element size");
		stride = get_array_stride(element_size);
	}

	assert(str[0] == #char "[", "Invalid object start %", str);
	remainder := advance(str);
	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder[0] == #char "]" {
		remainder = advance(remainder);
		// @Robustness: Do we need to zero out the array?
		return remainder, true;
	}


	if slot {
		array: Resizable_Array;

        initializer: (*void);
        if info.element_type.type == .STRUCT {
            struct_info := cast(*Type_Info_Struct) info.element_type;
            initializer = struct_info.initializer;
        }

		while true {
			Reflection.maybe_grow(*array, element_size);
            element_data := array.data + array.count * stride;
			if initializer {
				initializer(element_data);
			} else {
				memset(element_data, 0, element_size);
			}

			success: bool;
			remainder, success = parse_value(remainder, element_data, info.element_type, ignore_unknown, "", rename=rename);
			if !success	return remainder, false;

			array.count += 1;

			remainder = trim_left(remainder, WHITESPACE_CHARS);
			if remainder[0] != #char ","	break;
			remainder = advance(remainder);
			remainder = trim_left(remainder, WHITESPACE_CHARS);
		}
		if info.array_type == .VIEW {
			view := (cast(*Array_View_64) slot);
			view.count = array.count;
			view.data = array.data;
		} else {
			<<(cast(*Resizable_Array) slot) = array;
		}
	} else {
		while true {
			success: bool;
			remainder, success = parse_value(remainder, null, null, ignore_unknown, "", rename=rename);
			if !success	return remainder, false;

			remainder = trim_left(remainder, WHITESPACE_CHARS);
			if remainder[0] != #char ","	break;
			remainder = advance(remainder);
			remainder = trim_left(remainder, WHITESPACE_CHARS);
		}
	}

	if remainder[0] != #char "]"	return remainder, false;
	remainder = advance(remainder);
	return remainder, true;
}

Member_Offset :: struct {
    member: *Type_Info_Struct_Member;
    offset_in_bytes: s64;
}
// This procedure is somewhat copied from Basic.get_field.
fill_member_table :: (table: *Table(string, Member_Offset), info: *Type_Info_Struct, rename: Rename_Proc, base_offset := 0) {
    // First pass: Don't try recursing.
    for * member: info.members {
        name := rename(member);
        table_set(table, name, .{member, base_offset + member.offset_in_bytes});
    }

    // Second pass: See if we can get something recursively.
    for * info.members {
        if (it.flags & .USING) && (it.type.type == .STRUCT) {
            fill_member_table(table, cast(*Type_Info_Struct)it.type, rename, base_offset + it.offset_in_bytes);
        }
    }
}


parse_object :: (str: string, slot: *u8, info: *Type_Info_Struct, ignore_unknown: bool, rename: Rename_Proc) -> remainder: string, success: bool {
	assert(str[0] == #char "{", "Invalid object start %", str);
	remainder := advance(str);
	remainder = trim_left(remainder, WHITESPACE_CHARS);
	if remainder[0] == #char "}" {
		remainder = advance(remainder);
		return remainder, true;
	}

    // @Speed: Building this table every time is pretty silly.
    // We should probably either not build it at all or cache it somewhere.
	member_table: Table(string, Member_Offset);
	init(*member_table);
	defer deinit(*member_table);

	if info fill_member_table(*member_table, info, rename);

	while true {
		if remainder[0] != #char "\""	return remainder, false;

		key: string;
		success: bool;
		key, remainder, success = parse_string(remainder);
		if !success		return remainder, false;
		defer free(key);

		member_offset, member_found := table_find(*member_table, key);

		member_slot: *u8;
		member_info: *Type_Info;
		if member_found {
			member_slot = slot + member_offset.offset_in_bytes;
			member_info = member_offset.member.type;
		} else if !ignore_unknown {
			log_error("Missing member % in %", key, <<info);
			return remainder, false;
		}

		remainder = trim_left(remainder, WHITESPACE_CHARS);
		if remainder[0] != #char ":"	return remainder, false;
		remainder = advance(remainder);
		remainder = trim_left(remainder, WHITESPACE_CHARS);
		remainder, success = parse_value(remainder, member_slot, member_info, ignore_unknown, key, rename);
		if !success		return remainder, false;

		remainder = trim_left(remainder, WHITESPACE_CHARS);
		if remainder[0] != #char ","	break;
		remainder = advance(remainder);
		remainder = trim_left(remainder, WHITESPACE_CHARS);
	}

	if remainder[0] != #char "}"	return remainder, false;
	remainder = advance(remainder);
	return remainder, true;
}

parse_and_write_integer :: (info: *Type_Info_Integer, pointer: *void, string_value: string) -> bool, remainder: string {
    if info.signed {
        success, remainder := parse_and_write_integer(info, pointer, string_value, signed = true);
        return success, remainder;
    } else {
        success, remainder := parse_and_write_integer(info, pointer, string_value, signed = false);
        return success, remainder;
    }
}

parse_and_write_integer :: (info: *Type_Info_Integer, pointer: *void, string_value: string, $signed: bool) -> bool, remainder: string {
    #if signed {
        Int_Type :: s64;
    } else {
        Int_Type :: u64;
    }

    int_value, int_success, remainder := string_to_int(string_value, T = Int_Type);
    if !int_success {
        #if signed {
            log_error("Could not parse \"%\" as an integer.", string_value);
        } else {
            log_error("Could not parse \"%\" as an unsigned integer.", string_value);
        }
        return false, remainder;
    }

    valid, low, high := Reflection.range_check_and_store(int_value, info, pointer);

    if !valid {
        log_error("The value '%' is out of range. (It must be between % and %.)", int_value, low, high);
        return false, remainder;
    }

    return true, remainder;
}

Reflection :: #import "Reflection";
