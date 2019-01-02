gdods
=====

Gdods is a small GDScript for reading ODS files: the OpenDocument format for
spreadsheets used in for example  LibreOffice, and OpenOffice.

You can use this script to add support for ODS files to the game you're
building in the Godot game engine. It does not support all features that ODS
files have, but sticks mainly to reading text and images from columns, and
providing you with some functions to iterate over spreadsheets.

Gdods uses [gdunzip](https://github.com/jellehermsen/gdunzip) under the hood,
for extracting the contents of the ODS file (since ODS files are actualy a
bunch of xml's and other assets wrapped in a zip).

Using gdods
-----------
- Grab
  [gdunzip.gd](https://raw.githubusercontent.com/jellehermsen/gdods/master/src/gdunzip.gd)
  and
  [gdods.gd](https://raw.githubusercontent.com/jellehermsen/gdods/master/src/gdods.gd)
  and put them in the same folder in your Godot project.
- Make an instance, load a spreadsheet and start getting the data:

Example code
------------
```gdscript
# Create a gdods instance
var gdods = load('res://PATH_TO_GDODS/gdods.gd').new()

# Load an ODS file
var loaded = gdods.load('res://test/test.ods')

if !loaded:
    print('Could not load ODS file :-(')
else:
    # Get cell in sheet 0, row 2, column 1
    # NB: numbering starts from 0
    var cell = gdods.get_cell(0, 2, 1)

    # Verify that the cell is a TextCell
    if cell.type == gdods.TEXT_CELL:
        print('We have a text cell with this value: ' + cell.value)

    # Get another cell by using the named position
    var cell2 = gdods.get_cell_by_name('A42')

    # Verify that this cell is an ImageCell
    if cell2.type == gdods.IMAGE_CELL:
        print('We have got us an image cell')
        # Grab the actual image from the ODS file
        var image = cell2.load_image()
        if !image:
            print('Failed loading the image from the image cell')
        else:
            print('Image width is: ' + str(image.get_width())

    # Turn the second sheet with a header row into a array of dicts
    var dictarray = gdods.to_dictarray(1, 0)

    # Print the first row's value for the 'my_beautiful_key' column
    print(dictarray[0]['my_beautiful_key'])
```

Class documentation
-------------------

The gdods class inherits "reference", and upon initialization it loads
gdunzip.gd from the same directory gdods.gd resides.

### Member functions

| Returns                          | Function name          |
| -------------------------------- | ---------------------- |
| bool                             | load(String path)      |
| EmptyCell, TextCell or ImageCell | get_cell(int sheet_nr, int row_nr, int column_nr) |
| EmptyCell, TextCell or ImageCell | get_cell_by_name(int sheet_nr, String pos) |
| array, or false                  | to_dictarray(int sheet_nr, int header_row) |
|
