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
  [gdunzip.gd](https://raw.githubusercontent.com/jellehermsen/gdods/master/addons/gdods/gdunzip.gd)
  and
  [gdods.gd](https://raw.githubusercontent.com/jellehermsen/gdods/master/addons/gdods/gdods.gd)
  and put them in the same folder in your Godot project.
- Make an instance, load a spreadsheet and start getting the data:

Example code
------------
```gdscript
# Create a gdods instance
var gdods = load('res://addons/gdods/gdods.gd').new()

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
| Array, or false                  | to_dictarray(int sheet_nr, int header_row) |

### Constants

- EMPTY_CELL = 0
- TEXT_CELL = 1
- IMAGE_CELL = 2

### Member function description

- bool **load**(String path)

Tries to load an ODS file with a given path. Returns false if it failed
loading the ods, or true if it was successfull.

- *Cell* **get_cell**(int sheet_nr, int row_nr, int column_nr)

Given a sheet number, row number and column number
this method will return this cell's value, this
can either be a EmptyCell, TextCell or ImageCell instance.
If the cell can't be found it will return an EmptyCell

NB: numbering starts at 0

- *Cell* **get_cell_by_name**(int sheet_nr, int pos)

Return a cell by giving its name (i.e A1, D100).
Returns an empty cell if the cell can't be found, or if the input is incorrect.

- *Array* **to_dictarray**(int sheet_nr, int header_row)

If your sheet has a header row, you can use this function to transform all the
rows beneath the header row into a array of dicts. The header row will be used
as dictionary keys.  
This function returns false if the sheet denoted by
sheet_nr or the header_row can't be found.

### Inner classes

Gdods has 3 inner classes that are used for cell types: **TextCell**,
**ImageCell**, **EmptyCell**. Each of those has a to_string() function, and you can check the type
of the class by comparing the "type" attribute to one of the gdods' constants
(EMPTY_CELL / TEXT_CELL / IMAGE_CELL).

You can get the image path from **ImageCell** by using the *image_path*
attribute, and you can load the image by calling the *load_image* function with
no arguments. This will return either **false** or an Image instance.
