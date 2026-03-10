unit IsoMap;

interface

const
    MaxWidth = 120;
    MaxHeight = 150;
    MaxDepth = 3;

type
    PGameMap = ^GameMap;
    GameMap = object
        Depth, WidthInColumns, HeightInRows: Byte;
        NumTiles: Byte;
        Data: Array[0..MaxDepth - 1,0..MaxHeight - 1,0..MaxWidth - 1] of Byte;
        Walkable: Array[0..255] of Boolean;

        constructor Init(Filename: String);
        function TileAt(X, Y, Z: Word): Byte;
        function IsWalkable(X, Y: Word): Boolean;
    end;


implementation

constructor GameMap.Init;
var
   MapFile: file of Byte;
   Line: String;
   i, X, Y, Z: Word;
   LL: Word;
   W: Byte;
begin
     Assign(MapFile, Filename);
     Reset(MapFile);

     Read(MapFile, WidthInColumns);
     Read(MapFile, HeightInRows);
     Read(MapFile, Depth);
     Read(MapFile, NumTiles);

     for i := 0 to NumTiles - 1 do begin
         Read(MapFile, W);
         Walkable[i + 1] := W = 1;
     end;

     for Z := 0 to Depth - 1 do begin
         for Y := 0 to HeightInRows - 1 do begin
             for X := 0 to WidthInColumns - 1 do begin
                 Read(MapFile, Data[Z][Y][X]);
             end;
         end;
     end;

     Close(MapFile);
end;

function GameMap.TileAt;
var
   Index: Word;
begin
     if (X > MaxWidth) or (Y > MaxHeight) or (Z > MaxDepth) then begin
        TileAt := 0;
        Exit;
     end;


     TileAt := Data[Z][Y][X]
end;

function GameMap.IsWalkable;
var
   Z: Byte;
   Tile: Byte;
begin
     for Z := 0 to Depth - 1 do begin
         Tile := Data[Z][Y][X];

         if Tile = 0 then continue;

         if not Walkable[Tile] then begin
            IsWalkable := false;
            Exit;
         end;
     end;

     IsWalkable := true;
end;

end.