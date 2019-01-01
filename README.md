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

*NB: gdods is work in progress at the moment, and not yet usable!*
