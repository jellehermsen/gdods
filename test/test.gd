extends SceneTree

func _init():
    var gdods = load('res://src/gdods.gd').new()
    var loaded = gdods.load('res://test/test.ods')
    if loaded:
        print("ODS FILE LOADED")
    quit()

func _green_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;32m"
    return escape + code + text + escape + '[0;0m'

func _red_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;31m"
    return escape + code + text + escape + '[0;0m'
