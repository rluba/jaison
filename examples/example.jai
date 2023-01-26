
// Data structures for typed parsing/printing
LevelData :: struct {
    kind:     LevelKind;
    flags:    LevelFlags;
    secret:   bool;
    player:   Entity;
    player2:  *Entity;
    score:    float;
    entities: [..] Entity;

    floats:   [..] float;

    LevelKind :: enum {
        EASY      :: 0;
        HARD      :: 1;
        LEGENDARY :: 2;
    }

    LevelFlags :: enum_flags {
        FLAG_A :: 0x1;
        FLAG_B :: 0x2;
        FLAG_C :: 0x4;
    }
}

Entity :: struct {
    name: string;
    x, y: int;
    dirty: bool; @JsonIgnore
}


LEVEL_DATA_1_JSON := #string DONE
{"kind": ".HARD", "flags": ".FLAG_A | .FLAG_C", "secret": false,"score":5.5,"player": {"name": "Pat","x": 10,"y": 10},"player2": {"name": "Chris"},"entities": [{"name": "fdsa","x": 0,"y": 0},{"name": "fdsa","x": 0,"y": 0}], "floats": [0.00, 1.11111111111111111, 2.0202, 3e-5, 4.444444, -5.0]}
DONE;

LEVEL_DATA_2_JSON := #string DONE
{"kind": 2}
DONE;

typed_parsing :: () {
    {
        success, level := json_parse_string(LEVEL_DATA_1_JSON, LevelData, ignore_unknown=false);
        // success, level := json_parse_file("level.json", LevelData, ignore_unknown=false);
        assert(success);

        print("Typed parsing result 1:\n%\n\n", level);
        assert(level.floats.count == 6);
        assert(level.floats[1] > 1);  // Regression test, we had a bug here…
    }
    {
        // Test parsing integers into enum slots
        success, level := json_parse_string(LEVEL_DATA_2_JSON, LevelData, ignore_unknown=false);
        assert(success);

        print("Typed parsing result 2:\n%\n\n", level);

        assert(level.kind == .LEGENDARY);
    }
}

typed_printing :: () {
    level := LevelData.{kind=.LEGENDARY, flags=LevelData.LevelFlags.FLAG_B|.FLAG_C, secret=true, score=500};
    level.player = .{name="Pat", x=4, y=4, dirty=true};
    array_add(*level.entities, .{name="Chris", x=6, y=6});

    json_string := json_write_string(level);
    print("Typed printing result:\n%\n\n", json_string);

    // success := json_write_file("level.json", level, indent_char="");
    // assert(success);
}

generic_parsing :: () {
    // In this scenario, some parts of the structure are known, but other parts are not.

    json := #string DONE
{
    "version": 3,
    "entities": [
        {
            "name": "Player",
            "x": 2,
            "y": 2,
            "player_index": 0
        },
        {
            "name": "Snake",
            "x": 4,
            "y": 4,
            "snake_color": 1
        }
    ],
    "stuff": [null, true, false]
}
DONE

    success, root := json_parse_string(json);
    // success, root := json_parse_file("level.json");
    assert(success);

    print("Generic parsing result:\n");

    // Print things out, for demonstration purposes

    traverse_node :: (node: JSON_Value, depth: int) {
		INDENTATION :: 4;
        print("% ", node.type);

        if node.type == {
        case .NULL;
            print("\n");
        case .BOOLEAN;
            print("%\n", node.boolean);
        case .NUMBER;
            print("%\n", node.number);
        case .STRING;
            print("%\n", node.str);

        case .OBJECT;
            print("{\n");
            for node.object {
				for 1..(depth+1)*INDENTATION		print(" ");
                print("%: ", it_index);
                traverse_node(it, depth+1);
            }
			for 1..depth*INDENTATION		print(" ");
            print("}\n");

        case .ARRAY;
            print("[\n");
            for node.array {
				for 1..(depth+1)*INDENTATION		print(" ");
                traverse_node(it, depth + 1);
            }
			for 1..depth*INDENTATION		print(" ");
            print("]\n");
        }
    }

    traverse_node(root, 0);

    print("\n");



    // Convenience function for grabbing object members
    get :: (json_val: JSON_Value, key: string, expected_type: JSON_Type) -> JSON_Value {
        assert(json_val.type == .OBJECT);
        table := json_val.object;
        val, success := Hash_Table.table_find(table, key);
        assert(success);
        assert(val.type == expected_type);
        return val;
    }

    // Check for version number that may or may not exist
    version: float64 = -1;
    assert(root.type == .OBJECT);
    val, success2 := Hash_Table.table_find(root.object, "version");
    if success2 {
        if val.type == .NUMBER {
            version = val.number;
        }
    }
    print("version: %\n", version);

    // Traverse a structure we are confident about
    for get(root, "entities", .ARRAY).array {
        entity_name := get(it, "name", .STRING).str;
        x := get(it, "x", .NUMBER).number / 32;
        y := get(it, "y", .NUMBER).number / 32;

        if entity_name == {
			case "Player";
				player_index := cast(int) get(it, "player_index", .NUMBER).number;
				print("Player with player_index=%\n", player_index);
			case "Snake";
				snake_color := cast(int) get(it, "snake_color", .NUMBER).number;
				print("Snake with snake_color=%\n", snake_color);
			case;
				//...
        }
    }

    print("\n");
}

generic_printing :: () {
    // We want to write JSON with arbitrary structure.

    // Create and initialize object
    root_obj: JSON_Object;
    root := json_value(*root_obj);

    // Add music index to object, in certain cases
    should_add_music := true;
    if should_add_music {
        json_set(*root_obj, "music_index", .{type=.NUMBER, number=3});
    }

    // Create an array of values
	temp: [..] JSON_Value;
    junk := JSON_Value.{type=.STRING, str="junk"};
    array_add(*temp, junk);
    array_add(*temp, junk);

    // Create json array value
    array := JSON_Value.{type=.ARRAY};
    array.array = temp;

    // Add array to object
    json_set(*root_obj, "junk_array", array);

    // Print result
    json_string := json_write_string(root);
    print("Generic_printing result:\n%\n\n", json_string);

    //json_write_file("level.json", root);
}

rename_by_note :: () {
    // Sometimes the JSON we are parsing contains members with names we cannot use or don´t wanna.

    Message :: struct {
        value: string;
        _context: struct { // We cannot use "context" because it´s a reserved keyword in Jai.
            channel: int;
            parent: int;
        } @JsonName(context) // This member in JSON is "context" but we need to have it as "_context". So we can use the JsonName note to encode and decode it as "context".
    }

    json := #string DONE
    {
        "value": "Hello!",
        "context": {
            "channel": 1,
            "parent": 897820
        }
    }
    DONE

    success, message_decoded := json_parse_string(json, Message, ignore_unknown = false);
    assert(success);

    print("Rename_by_note decode result:\n%\n\n", message_decoded);
    assert(message_decoded._context.channel == 1);


    message_encoded := json_write_string(message_decoded);
    print("Rename_by_note encode result:\n%\n\n", message_encoded);

    assert(message_encoded.count != 0);
    assert(find_index_from_left(message_encoded, "_context") == -1);
}

custom_rename_procedure :: () {
    // We can also pass a custom rename procedure for renaming certain members.

    rename_to_upper :: (member: *Type_Info_Struct_Member) -> string {
        return to_upper_copy(member.name);
    }

    player := Entity.{
        name="Player",
        x = 10,
        y = 50
    };

    player_encoded := json_write_string(player, rename=rename_to_upper);
    assert(player_encoded.count != 0);

    print("encoded with rename_to_upper:\n%\n\n", player_encoded);
    assert(find_index_from_left(player_encoded, "name") == -1);
    assert(find_index_from_left(player_encoded, "NAME") != -1);

    success, player_decoded := json_parse_string(player_encoded, Entity, ignore_unknown = false, rename = rename_to_upper);
    assert(success);
    print("decoded with rename_to_upper:\n%\n\n", player_decoded);
    assert(player_decoded.name == "Player");
}

decode_into_struct_with_using :: () {
    Coordinates :: struct {
        x: int;
        y: int;
    }

    Tile :: struct {
        color: string;
        using coordinates: Coordinates;
    }

    JSON :: #string END
    {
        "color": "green",
        "x": 1,
        "y": 3
    }
    END

    success, tile := json_parse_string(JSON, Tile, ignore_unknown = false);
    assert(success);
    print("Decoded tile: %", tile);
    assert(tile.color == "green");
    assert(tile.x == 1);
    assert(tile.y == 3);
}

main :: () {
    Debug.init();

	{
		// Use the temporary allocator so we don't have to worry about individually freeing
		// all the allocations.
		push_allocator(temp);

		typed_parsing();
		typed_printing();
		generic_parsing();
		generic_printing();
        rename_by_note();
        custom_rename_procedure();
        decode_into_struct_with_using();
	}

    // Since the program ends here, this doesn't matter, but just setting an example.
    reset_temporary_storage();
}

#import, file "../module.jai";

#import "Basic";
#import "Hash_Table"; // To be able to iterate over node.object
#import "String"; // For to_upper_copy
#import "Compiler"; // For Type_Info_Struct_Member
Debug :: #import "Debug";
Hash_Table :: #import "Hash_Table";
