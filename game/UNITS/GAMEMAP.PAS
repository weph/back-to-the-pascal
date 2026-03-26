unit GameMap;

interface

type
    PGameMap = ^TGameMap;
    TGameMap = object
        LayerSize: LongInt;
        Width, Height: LongInt;
        Depth: Byte;
        NumTiles: Byte;
        Layers: array[0..255] of PChar;
        Walkable: Array[0..255] of Boolean;

        constructor Init(Filename: String);
        destructor Destroy;
        function TileAt(X, Y, Z: Word): Byte;
        function IsWalkable(X, Y: Word): Boolean;
    end;


implementation

uses Malloc, VGA, Debug;

constructor TGameMap.Init;
var
   MapFile: file;
   Line: String;
   i, X, Y, Z: Word;
   LL: Word;
   W: Byte;
   Tile: Byte;
   SW: PStopwatch;
begin
     SW := Profiler^.Stopwatch('TGameMap.Init');
     SW^.Start;

     Assign(MapFile, Filename);
     Reset(MapFile, 1);

     BlockRead(MapFile, Width, 2);
     BlockRead(MapFile, Height, 2);
     BlockRead(MapFile, Depth, 1);
     BlockRead(MapFile, NumTiles, 1);

     LayerSize := Width * Height;

     for i := 0 to NumTiles - 1 do begin
         BlockRead(MapFile, W, 1);
         Walkable[i + 1] := W = 1;
     end;

     for Z := 0 to Depth - 1 do begin
         M_Alloc(Layers[Z], LayerSize);
         BlockRead(MapFile, Layers[Z]^, LayerSize);
     end;

     Close(MapFile);

     SW^.Stop;
end;

destructor TGameMap.Destroy;
var
   i: Byte;
begin
     for i := 0 to Depth - 1 do begin
         M_Free(Layers[i], LayerSize);
     end;
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