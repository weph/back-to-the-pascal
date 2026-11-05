LogicalScreenHeight     EQU     272
ColumnWidth             EQU     8
RowHeight               EQU     16
PlaneWidth              EQU     96
PlaneSize               EQU     PlaneWidth * LogicalScreenHeight
RowSize                 EQU     PlaneWidth * RowHeight
ScIndex                 EQU     03c4h
GcIndex                 EQU     03ceh
GcData                  EQU     03cfh
PaletteMask             EQU     03c6h
PaletteWrite            EQU     03c8h
PaletteData             EQU     03c9h
