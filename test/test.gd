extends SceneTree

func _init():
    var gdods = load('res://src/gdods.gd').new()
    var loaded = gdods.load('res://test/test.ods')
    if loaded:
        print("ODS FILE LOADED")
        var cell = gdods.get_cell_by_name(1, 'B3')
        print(cell.to_string())

        var ugh = gdods.to_dictarray(1, 2)
        for item in ugh:
            print(item['id'] + '-' + item['animal'] + '-' + item['awesomeness multiplier'])

    quit()

func _green_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;32m"
    return escape + code + text + escape + '[0;0m'

func _red_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;31m"
    return escape + code + text + escape + '[0;0m'
