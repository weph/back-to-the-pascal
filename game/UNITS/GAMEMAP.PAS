unit GameMap;

interface

type
    TCellTiles = record
        Top, Left, Right, Bottom: Byte;
    end;

    PGameMap = ^TGameMap;
    TGameMap = object
        LayerSize: LongInt;
        Width, Height: LongInt;
        Depth: Byte;
        NumTiles: Byte;
        Layers: array[0..255] of PChar;
        Walkable: array[0..255] of Boolean;
        RowOffsets: array[0..255] of Word;

        constructor Init(Filename: string);
        destructor Destroy;
        function TileAt(X, Y, Z: Word): Byte;
        procedure CellTilesAt(X, Y, Z: Word; var Result: TCellTiles);
        function IsWalkable(X, Y: Word): Boolean;
    end;

implementation

uses
    Malloc,
    VGA,
    Debug;

constructor TGameMap.Init;
var
    MapFile: file;
    i, Z: Word;
    W: Byte;
    SW: TStopwatch;
begin
    SW.Init('TGameMap.Init');

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

    for i := 0 to Height - 1 do begin
        RowOffsets[i] := i * Width;
    end;

    SW.Stop;
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
begin
    if (X >= Width) or (Y >= Height) or (Z >= Depth) then begin
        TileAt := 0;
        Exit;
    end;

    TileAt := Byte(Layers[Z][Y * Width + X]);
end;

procedure TGameMap.CellTilesAt(X, Y, Z: Word; var Result: TCellTiles);
var
    Offset: Word;
begin
    Offset := RowOffsets[Y] + X;

    Result.Top := Byte(Layers[Z][Offset]);

    if ((Y + 1) < Height) then begin
        Result.Left := Byte(Layers[Z][Offset + Width - 1]);
        Result.Right := Byte(Layers[Z][Offset + Width]);
    end
    else begin
        Result.Left := 0;
        Result.Right := 0;
    end;

    if ((Y + 2) < Height) then begin
        Result.Bottom := Byte(Layers[Z][Offset + Width + Width]);
    end
    else begin
        Result.Bottom := 0;
    end;
end;

function TGameMap.IsWalkable;
var
    Z: Byte;
    Tile: Byte;
begin
    for Z := 0 to Depth - 1 do begin
        Tile := Byte(Layers[Z][Y * Width + X]);

        if Tile = 0 then
            continue;

        if not Walkable[Tile] then begin
            IsWalkable := false;
            Exit;
        end;
    end;

    IsWalkable := true;
end;

end.
