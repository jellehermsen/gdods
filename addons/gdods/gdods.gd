# MIT License
# 
# Copyright (c) 2018 Jelle Hermsen
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 

var sheets = []

var _gdunzip
var _xml

# Current node type, name and offset
var _node_type = 0
var _node_name = ""
var _node_offset = -1

const EMPTY_CELL = 0
const TEXT_CELL = 1
const IMAGE_CELL = 2

# Initialize the gdods class
func _init():
    var script_path = self.get_script().get_path().get_base_dir()
    self._gdunzip = load(script_path + '/gdunzip.gd').new()

# Tries to load an ODS file with a given path. Returns false if it failed
# loading the ods, or true if it was successfull.
func load(path):
    var loaded = self._gdunzip.load(path) 

    if !loaded:
        print('Could not load ods with path: ' + path)
        return false

    if (!('mimetype' in self._gdunzip.files) 
        || !('content.xml' in self._gdunzip.files)
    ):
        print('Invalid ODS')
        return false

    var mimetype = self._gdunzip.uncompress('mimetype')

    if !mimetype || (
        mimetype.get_string_from_ascii()
        != 'application/vnd.oasis.opendocument.spreadsheet'
    ):
        print('ODS file has invalid mimetype')
        return false

    var content = self._gdunzip.uncompress('content.xml')
    if !content:
        print('Could not read content.xml from ODS')
        return false

    self._xml = XMLParser.new()
    var result = self._xml.open_buffer(content)

    var sheet = self._parse_sheet()
    if !sheet:
        return false
    while sheet:
        self.sheets.append(sheet)
        sheet = self._parse_sheet()

    return true

# Given a sheet number, row number and column number
# this method will return this cell's value, this
# can either be a EmptyCell, TextCell or ImageCell instance.
# If the cell can't be found it will return an EmptyCell
# NB: numbering starts at 0
func get_cell(sheet_nr, row_nr, column_nr):
    if sheet_nr < 0 || row_nr < 0 || column_nr < 0:
        return EmptyCell.new()

    if len(sheets) <= sheet_nr:
        return EmptyCell.new()

    var sheet = sheets[sheet_nr]
    if len(sheet) <= row_nr:
        return EmptyCell.new()

    var row = sheets[sheet_nr][row_nr]
    if len(row) <= column_nr:
        return EmptyCell.new()

    return row[column_nr]

# Return a cell by giving its name (i.e A1, D100)
# Returns an empty cell if the cell can't be found, or if the input is
# incorrect
func get_cell_by_name(sheet_nr, pos):
    var row_col = self._convert_name_to_row_col(pos)
    if !row_col:
        return EmptyCell.new()
    return get_cell(sheet_nr, row_col[0], row_col[1])

# If your sheet has a header row, you can use this function to transform all
# the rows beneath the header row into a array of dicts. The header row will be
# used as dictionary keys.
# This function returns false if the sheet denoted by sheet_nr or the
# header_row can't be found
func to_dictarray(sheet_nr, header_row):
    if len(sheets) <= sheet_nr:
        return false

    var sheet = sheets[sheet_nr]
    if len(sheet) <= header_row:
        return false

    var header = []
    for title in sheet[header_row]:
        var name = title.to_string()
        if name == '':
            break
        header.append(name)

    var result = []

    for i in range(header_row + 1, len(sheet)):
        var row = sheet[i]
        var item = {}
        var col = 0
        var row_length = len(row)
        for title in header:
            if row_length <= col:
                item[title] = EmptyCell.new()
            else:
                item[title] = row[col].to_string()
            col += 1
        result.append(item)
    return result

# ---------------
# Private methods
# ---------------
const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'
    , 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

# Convert a given cell name to an array in the form of (row, col),
# I.E: A1 == [0, 0] and Z10 == [9, 25]
func _convert_name_to_row_col(name):
    var row = ''
    var col = 0

    for i in range(0, len(name)):
        var chr = name[i]
        if chr.is_valid_integer():
            row += chr
        elif chr.to_upper() in self._letters:
            col = col * 26 + self._letters.find(chr.to_upper()) + 1
        else:
            return false

    return [int(row) - 1, col - 1]

func _next_node():
    self._xml.read()

    var new_offset = self._xml.get_node_offset()
    if new_offset == self._node_offset:
        return false

    self._node_type = self._xml.get_node_type()
    if self._node_type in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END]:
        self._node_name = self._xml.get_node_name()
    else:
        self._node_name = ''
    self._node_offset = new_offset
    return true

# Returns whether the current node is an "end element", i.e </node>
func _end():
    return self._node_type == XMLParser.NODE_ELEMENT_END

# Returns whether the current node has given name, and is an end element
func _end_node(name):
    return self._node_name == name && self._end()

# Parse a spreadsheet, return a list of rows
func _parse_sheet():
    # Skip all nodes, until we reach the first "table:table" node
    while self._next_node() && self._node_name != 'table:table':
        pass

    # We should have arrived at a table, if we haven't there's something
    # wrong with the content.xml
    if self._node_name != 'table:table':
        return false

    var rows = []

    # Skip all nodes, until we arrive at the end of the table
    while self._next_node() && !self._end_node('table:table'):
        if self._node_name == 'table:table-row':
            # In the ODS file format rows can be repeated (by using the
            # attribute "table-number-rows-repeated")
            var count = 1
            var repeated = self._xml.get_named_attribute_value_safe(
                'table:number-rows-repeated'
            )
            var empty_row = self._xml.is_empty()
            if repeated != "":
                count = int(repeated)
            var row = []
            if !empty_row:
                row = self._parse_row()
            for i in range(count):
                rows.append(row)

    return rows

# Parse a row, returns an array of cells.
func _parse_row():
    var cells = []

    while self._next_node() && !self._end_node('table:table-row'):
        if self._node_name == 'table:table-cell':
            var count = 1
            var repeated = self._xml.get_named_attribute_value_safe(
                'table:number-columns-repeated'
            )
            var empty_cell = self._xml.is_empty()
            if repeated != "":
                count = int(repeated)
            var cell = null
            if !empty_cell:
                cell = self._parse_cell()
            else:
                cell = EmptyCell.new()
            for i in range(count):
                cells.append(cell)

    return cells

# Parse a cell
func _parse_cell():
    var text_value = ""
    var image_path = ""
    var has_contents = false

    while self._next_node() && !self._end_node('table:table-cell'):
        if self._node_name == 'draw:image' && !self._end():
            has_contents = true
            image_path = self._xml.get_named_attribute_value_safe(
                'xlink:href'
            )
        elif self._node_type == XMLParser.NODE_TEXT:
            has_contents = true
            text_value += self._xml.get_node_data()
        elif self._node_name == 'text:p' && !self._end() && text_value != '':
            has_contents = true
            text_value += '\n'

    if !has_contents:
        return EmptyCell.new()
    if image_path != '':
        return ImageCell.new(image_path, self._gdunzip)
    else:
        return TextCell.new(text_value)

# -------------
# Inner classes
# -------------

class EmptyCell:
    const type = 0

    func _init():
        pass

    func to_string():
        return ''

class TextCell:
    const type = 1

    var value = ''

    func _init(value):
        self.value = value

    func to_string():
        return self.value

class ImageCell:
    const type = 2

    var image_path = ''
    var _gdunzip

    func _init(image_path, gdunzip):
        self._gdunzip = gdunzip
        self.image_path = image_path

    # Tries to get the image from the ODS file, and return it.
    # Returns false on failure.
    func load_image():
        var uncompressed = self._gdunzip.uncompress(self.image_path)
        if !uncompressed:
            return false
        var image = Image.new()
        var file_parts = self.image_path.to_lower().split('.')
        var extension = file_parts[-1]

        if extension == 'png':
            image.load_png_from_buffer(uncompressed)
            return image

        if extension == 'jpg' || extension == 'jpeg':
            image.load_jpg_from_buffer(uncompressed)
            return image

        return false

    func to_string():
        return '[' + image_path + ']'
