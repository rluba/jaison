
// Data structures for typed parsing/printing
LevelData :: struct {
    secret: bool;
    player: Entity;
    player2: *Entity;
    entities: [..]Entity;
}

Entity :: struct {
    name: string;
    x, y: int;
    dirty: bool; @JsonIgnore
}

typed_parsing :: () {
    json := #string DONE
{"secret": false,"player": {"name": "Pat","x": 10,"y": 10},"player2": {"name": "Chris"},"entities": [{"name": "fdsa","x": 0,"y": 0},{"name": "fdsa","x": 0,"y": 0}]}
DONE;

    level, success := json_parse_string(json, LevelData, ignore_unknown=false);
    //level, success := json_parse_file("level.json", LevelData, ignore_unknown=false);
    assert(success);

    print("typed parsing result:\n%\n\n", level);
}

typed_printing :: () {
    level := LevelData.{secret=true};
    level.player = .{name="Pat", x=4, y=4, dirty=true};
    array_add(*level.entities, .{name="Chris", x=6, y=6});

    json_string := json_write_string(level);
    print("typed printing result:\n%\n\n", json_string);

    //success := json_write_file("level.json", level, indent_char="");
    //assert(success);
}

generic_parsing :: () {
    // In this scenario, some parts of the structure is known, but other parts are not.

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
    root, success := json_parse_string(json);
    //root, success := json_parse_file("level.json");
    assert(success);

    print("generic parsing result:\n");

    // Print things out, for demonstration purposes

    traverse_node :: (node: JSON_Value) {
        print("% ", node.type);

        if node.type == {
        case .NULL;
            print("\n");
        case .BOOLEAN;
            print("%\n", node.value.boolean);
        case .NUMBER;
            print("%\n", node.value.number);
        case .STRING;
            print("%\n", node.value.str);

        case .OBJECT;
            print("{\n");
            for node.value.object {
                print("%: ", it_index);
                traverse_node(it);
            }
            print("}\n");

        case .ARRAY;
            print("[\n");
            for node.value.array {
                traverse_node(it);
            }
            print("]\n");
        }
    }

    traverse_node(root);

    print("\n");



    // Convenience function for grabbing object members
    get :: (json_val: JSON_Value, key: string, expected_type: JSON_Type) -> JSON_Value {
        assert(json_val.type == .OBJECT);
        table := <<json_val.value.object;
        val, success := Hash_Table.table_find(table, key);
        assert(success);
        assert(val.type == expected_type);
        return val;
    }

    // Check for version number that may or may not exist
    version: float64 = -1;
    assert(root.type == .OBJECT);
    val, success2 := Hash_Table.table_find(<<root.value.object, "version");
    if success2 {
        if val.type == .NUMBER {
            version = val.value.number;
        }
    }
    print("version: %\n");

    // Traverse a structure we are confident about
    for get(root, "entities", .ARRAY).value.array {
        entity_name := get(it, "name", .STRING).value.str;
        x := get(it, "x", .NUMBER).value.number / 32;
        y := get(it, "y", .NUMBER).value.number / 32;

        if entity_name == {
        case "Player";
            player_index := cast(int) get(it, "player_index", .NUMBER).value.number;
            print("Player with player_index=%\n", player_index);
        case "Snake";
            snake_color := cast(int) get(it, "snake_color", .NUMBER).value.number;
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
        json_set(*root_obj, "music_index", .{type=.NUMBER, value.number=3});
    }

    // Create array
    array := JSON_Value.{type=.ARRAY};

    // Initialize array
	temp: [..]JSON_Value;
    array.value.array = temp;

    // Add things to array
    junk := JSON_Value.{type=.STRING, value.str="junk"};
    array_add(*array.value.array, junk);
    array_add(*array.value.array, junk);

    // Add array to object
    json_set(*root_obj, "junk_array", array);

    // Print result
    json_string := json_write_string(root);
    print("generic_printing result:\n%\n\n", json_string);

    //json_write_file("level.json", root);
}

main :: () {
    Debug.init();

    // Use the temporary allocator so we don't have to worry about individually freeing
    // all the allocations.
    new_context := context;
    new_context.allocator = __temporary_allocator;
    new_context.allocator_data = null;
    push_context new_context {

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
