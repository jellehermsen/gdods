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

    if !('mimetype' in self._gdunzip.files) || !('content.xml' in self._gdunzip.files):
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

    print(sheets)

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

func _skip_node():
    self._xml.skip_section()

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
            # In the ODS file format rows can be repeated (by using the attribute
            # "table-number-rows-repeated" set on the table:table-row attribute).
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
            for i in range(count):
                cells.append(cell)

    return cells

# Parse a cell
func _parse_cell():
    var text_value = ""
    var image = ""
    var has_contents = false

    while self._next_node() && !self._end_node('table:table-cell'):
        if self._node_name == 'draw:image' && !self._end():
            has_contents = true
            image = self._xml.get_named_attribute_value_safe(
                'xlink:href'
            )
        elif self._node_type == XMLParser.NODE_TEXT:
            has_contents = true
            text_value += self._xml.get_node_data()
        elif self._node_name == 'text:p' && !self._end() && text_value != '':
            has_contents = true
            text_value += '\n'

    if !has_contents:
        return null
    if image != '':
        return {'type': 'image', 'value': image}
    else:
        return {'type': 'text', 'value': text_value}
