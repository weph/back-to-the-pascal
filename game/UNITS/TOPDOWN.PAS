unit TopDown;

interface

uses
    Globals,
    Types,
    Image,
    GameMap,
    Sprite;

type
    PTopDownMapRenderer = ^TTopDownMapRenderer;
    TTopDownMapRenderer = object
        public
            constructor Init(_Map: PGameMap; TilesetFilename: String);
            destructor Destroy;
            procedure Update(Page: Byte; Scroll: TCoordinate);
            procedure Draw(
                Page: Byte;
                Offset: TCoordinate;
                Start: TCoordinate
            );
            procedure DrawLayersCoveringSprite(
                Page: Byte;
                Scroll: TCoordinate;
                Sprite: PSprite
            );

        private
            Map: PGameMap;
            Tiles: array[1..255] of PImage;
            LastRedraw: array[0..1] of TCoordinate;

            procedure DrawPartialMap(
                Page: Byte;
                Offset: TCoordinate;
                StartLayer, EndLayer: Byte;
                StartCol, EndCol: Word;
                StartRow, EndRow: Word;
                Start: TCoordinate
            );
            procedure DrawLastColumn(
                Page: Byte;
                Offset: TCoordinate;
                Start: TCoordinate
            );
            procedure DrawFirstColumn(
                Page: Byte;
                Offset: TCoordinate;
                Start: TCoordinate
            );
            procedure DrawLastRow(
                Page: Byte;
                Offset: TCoordinate;
                Start: TCoordinate
            );
            procedure DrawFirstRow(
                Page: Byte;
                Offset: TCoordinate;
                Start: TCoordinate
            );
    end;

implementation

uses
    PCXImg,
    VGA,
    ModeX;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

var
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;

constructor TTopDownMapRenderer.Init(_Map: PGameMap; TilesetFilename: String);
var
   Img: PCXImage;
   i, X, Y, Page: Byte;
begin
     Map := _Map;

     Img.Init(TilesetFilename);
     for i := 0 to 255 do begin
         SetColor(i, Img.Palette[i]);
     end;

     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Tiles[Y * 20 + X + 1] := Img.ImageAt(X * 16, Y * 16, 16, 16);
         end;
     end;

     Img.Destroy;

     for Page := 0 to 1 do begin
         LastRedraw[Page].X := -1;
         LastRedraw[Page].Y := -1;
     end;
end;

destructor TTopDownMapRenderer.Destroy;
var
   X, Y: Byte;
begin
     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Dispose(Tiles[Y * 20 + X + 1], Destroy);
         end;
     end;
end;

procedure TTopDownMapRenderer.DrawPartialMap(
    Page: Byte;
    Offset: TCoordinate;
    StartLayer, EndLayer: Byte;
    StartCol, EndCol: Word;
    StartRow, EndRow: Word;
    Start: TCoordinate
);
var
   Z, Col, Row: Word;
   Tile: Byte;
begin
     for Z := StartLayer to EndLayer do begin
         for Row := StartRow to EndRow do begin
             for Col := StartCol to EndCol do begin
                 Tile := Map^.TileAt(Offset.X + Col, Offset.Y + Row, Z);

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      X_Draw(Page, Start.X + X, Start.Y + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;

procedure TTopDownMapRenderer.DrawLastColumn(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map^.Depth - 1,
         MapCols - 1, MapCols - 1,
         0, MapRows - 1,
         Start
     );
end;

procedure TTopDownMapRenderer.DrawFirstColumn(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map^.Depth - 1,
         0, 0,
         0, MapRows - 1,
         Start
     );
end;

procedure TTopDownMapRenderer.DrawLastRow(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map^.Depth - 1,
         0, MapCols - 1,
         MapRows - 1, MapRows - 1,
         Start
     );
end;

procedure TTopDownMapRenderer.DrawFirstRow(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map^.Depth - 1,
         0, MapCols - 1,
         0, 0,
         Start
     );
end;

procedure TTopDownMapRenderer.Draw(
    Page: Byte;
    Offset: TCoordinate;
    Start: TCoordinate
);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map^.Depth - 1,
         0, MapCols - 1,
         0, MapRows - 1,
         Start
     );
end;

procedure TTopDownMapRenderer.DrawLayersCoveringSprite(
    Page: Byte;
    Scroll: TCoordinate;
    Sprite: PSprite
);
var
   X1, Y1, X2, Y2: Integer;
   StartZ: Word;
   NextRedraw: TCoordinate;
   MapRedrawStart: TCoordinate;
begin
     if Sprite^.Z = 65535 then Exit;

     NextRedraw.X := Scroll.X div TileWidth;
     NextRedraw.Y := Scroll.Y div TileHeight;
     MapRedrawStart.X := NextRedraw.X * TileWidth;
     MapRedrawStart.Y := NextRedraw.Y * TileHeight;

     with Sprite^ do begin
          X1 := (X div TileWidth) - NextRedraw.X;
          Y1 := ((Y - Z) div TileHeight) - NextRedraw.Y;
          X2 := ((X + Width + TileWidth - 1) div TileWidth) - NextRedraw.X;
          Y2 := ((Y - Z + Height + TileHeight - 1) div TileHeight) - NextRedraw.Y;
     end;

     DrawPartialMap(
         Page,
         NextRedraw,
         1, Map^.Depth - 1,
         X1, X2,
         Y1, Y2,
         MapRedrawStart
     );
end;

procedure TTopDownMapRenderer.Update(Page: Byte; Scroll: TCoordinate);
var
   NextRedraw: TCoordinate;
   MapRedrawStart: TCoordinate;
begin
     NextRedraw.X := Scroll.X div TileWidth;
     NextRedraw.Y := Scroll.Y div TileHeight;
     MapRedrawStart.X := NextRedraw.X * TileWidth;
     MapRedrawStart.Y := NextRedraw.Y * TileHeight;

     if NextRedraw.X > LastRedraw[Page].X then begin
         DrawLastColumn(Page, NextRedraw, MapRedrawStart);
     end else if NextRedraw.X < LastRedraw[Page].X then begin
         DrawFirstColumn(Page, NextRedraw, MapRedrawStart);
     end;

     if NextRedraw.Y > LastRedraw[Page].Y then begin
         DrawLastRow(Page, NextRedraw, MapRedrawStart);
     end else if NextRedraw.Y < LastRedraw[Page].Y then begin
         DrawFirstRow(Page, NextRedraw, MapRedrawStart);
     end;

     LastRedraw[Page] := NextRedraw;
end;

procedure InitTilePositions;
var
   Row, Col: Word;
begin
     for Row := 0 to MapRows - 1 do begin
         for Col := 0 to MapCols - 1 do begin
             with TilePositions[Row][Col] do begin
                  X := Col * TileWidth;
                  Y := Row * TileHeight;
             end;
         end;
     end;
end;

begin
     InitTilePositions;
end.