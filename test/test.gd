extends SceneTree

func _init():
    var gdods = load('res://addons/gdods/gdods.gd').new()
    var loaded = gdods.load('res://test/test.ods')

    if !loaded:
        _fail('Could not load ODS file')
        return quit()

    _success('Loaded ODS file')

    var cell = gdods.get_cell(0, 2, 1)
    if !cell:
        _fail('Could not get cell')
    else:
        if cell.type == gdods.TEXT_CELL:
            _success('Got cell type')
        if cell.value == 'B3':
            _success('Verified cell value')

    cell = gdods.get_cell_by_name(0, 'ACQ220')
    if !cell:
        _fail('Could not get cell value by name')
    else:
        if cell.to_string() == 'TEST':
            _success('Got cell value by name')
        else:
            _fail('Failed to get cell value by name')

    var dict = gdods.to_dictarray(1, 2)
    if !dict:
        _fail('Failed to turn sheet into dictarray')
    else:
        _success('Turned sheet into dictarray')
        if dict[5]['awesomeness multiplier'] != '1000':
            _fail('Failed to get value from dictarray')
        else:
            _success('Got value from dictarray')

    var image = gdods.get_cell_by_name(0, 'A7').load_image()
    if !image:
        _fail('Failed to load image from sheet')
    else:
        _success('Retrieved image from sheet')
        if image.get_width() == 365 && image.get_height() == 547:
            _success('Verified image size')
        else:
            _fail('Image size wrong')

    quit()

func _success(text):
    print(_green_text('✓') + ' ' + text)

func _fail(text):
    print(_red_text('✗') + ' ' + text)

func _green_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;32m"
    return escape + code + text + escape + '[0;0m'

func _red_text(text):
    var escape = PoolByteArray([0x1b]).get_string_from_ascii()
    var code = "[1;31m"
    return escape + code + text + escape + '[0;0m'
