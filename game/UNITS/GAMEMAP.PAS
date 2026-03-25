unit GameMap;

interface

type
    PGameMap = ^TGameMap;
    TGameMap = object
        LayerSize: Word;
        Depth, Width, Height: Byte;
        NumTiles: Byte;
        Layers: array[0..255] of PChar;
        Walkable: Array[0..255] of Boolean;

        constructor Init(Filename: String);
        function TileAt(X, Y, Z: Word): Byte;
        function IsWalkable(X, Y: Word): Boolean;
    end;


implementation

constructor TGameMap.Init;
var
   MapFile: file of Byte;
   Line: String;
   i, X, Y, Z: Word;
   LL: Word;
   W: Byte;
   Tile: Byte;
begin
     Assign(MapFile, Filename);
     Reset(MapFile);

     Read(MapFile, Width);
     Read(MapFile, Height);
     Read(MapFile, Depth);
     Read(MapFile, NumTiles);

     LayerSize := Width * Height;
     for i := 0 to Depth - 1 do begin
         GetMem(Layers[i], LayerSize);
     end;

     for i := 0 to NumTiles - 1 do begin
         Read(MapFile, W);
         Walkable[i + 1] := W = 1;
     end;

     for Z := 0 to Depth - 1 do begin
         for Y := 0 to Height - 1 do begin
             for X := 0 to Width - 1 do begin
                 Read(MapFile, Byte(Layers[Z][Y * Width + X]));
             end;
         end;
     end;

     Close(MapFile);
end;

function TGameMap.TileAt;
var
   Index: Word;
begin
     if (X >= Width) or (Y >= Height) or (Z >= Depth) then begin
        TileAt := 0;
        Exit;
     end;


     TileAt := Byte(Layers[Z][Y * Width + X]);
end;

function TGameMap.IsWalkable;
var
   Z: Byte;
   Tile: Byte;
begin
     for Z := 0 to Depth - 1 do begin
         Tile := Byte(Layers[Z][Y * Width + X]);

         if Tile = 0 then continue;

         if not Walkable[Tile] then begin
            IsWalkable := false;
            Exit;
         end;
     end;

     IsWalkable := true;
end;

end.