
// Data structures for typed parsing/printing
LevelData :: struct {
    secret: bool;
    player: Entity;
    player2: *Entity;
	score: float;
    entities: [..] Entity;
}

Entity :: struct {
    name: string;
    x, y: int;
    dirty: bool; @JsonIgnore
}


LEVEL_DATA_JSON := #string DONE
{"secret": false,"score":5.5,"player": {"name": "Pat","x": 10,"y": 10},"player2": {"name": "Chris"},"entities": [{"name": "fdsa","x": 0,"y": 0},{"name": "fdsa","x": 0,"y": 0}]}
DONE;

typed_parsing :: () {

    success, level := json_parse_string(LEVEL_DATA_JSON, LevelData, ignore_unknown=false);
    // success, level := json_parse_file("level.json", LevelData, ignore_unknown=false);
    assert(success);

    print("Typed parsing result:\n%\n\n", level);
}

typed_printing :: () {
	level := LevelData.{secret=true, score=500};
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
        table := <<json_val.object;
        val, success := Hash_Table.table_find(table, key);
        assert(success);
        assert(val.type == expected_type);
        return val;
    }

    // Check for version number that may or may not exist
    version: float64 = -1;
    assert(root.type == .OBJECT);
    val, success2 := Hash_Table.table_find(<<root.object, "version");
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
	}

    // Since the program ends here, this doesn't matter, but just setting an example.
    reset_temporary_storage();
}

#load "../module.jai"; // In your code, you should do an #import instead of a #load (possibly using Compiler.Build_Options.modules_search_path_array)

#import "Basic";
Debug :: #import "Debug";
Hash_Table :: #import "Hash_Table";
