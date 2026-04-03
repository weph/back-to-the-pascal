unit Renderer;

interface

uses Types, Sprite;

procedure R_Init(TilesetFilename: String);

procedure R_AddSprite(Sprite: PSprite);

procedure R_InitScreen;

procedure R_Render(Page: Byte; Scroll: TCoordinate);

procedure R_Destroy;

implementation

uses Globals, ModeX, Image, PCXImg, VGA;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

var
   Tiles: array[1..255] of PImage;
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;
   LastRedraw: array[0..1] of TCoordinate;
   Sprites: array[0..255] of PSprite;
   NumSprites: Byte;
   DirtyRects: array[0..1,0..255] of TDirtyRect;

procedure DrawPartialMap(
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
                 Tile := Map.TileAt(Offset.X + Col, Offset.Y + Row, Z);

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      X_Draw(Page, Start.X + X, Start.Y + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;

procedure DrawMap(Page: Byte; Offset: TCoordinate; StartCol, EndCol, StartRow, EndRow: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map.Depth - 1,
         StartCol, EndCol,
         StartRow, EndRow,
         Start
     );
end;

procedure DrawLayersCoveringSprite(Page: Byte; Offset: TCoordinate; Start: TCoordinate; Sprite: PSprite);
var
   X1, Y1, X2, Y2: Integer;
   StartZ: Word;
begin
     if Sprite^.Z = 65535 then Exit;

     with Sprite^ do begin
          X1 := (X div TileWidth) - Offset.X;
          Y1 := ((Y - Z) div TileHeight) - Offset.Y;
          X2 := ((X + Width + TileWidth - 1) div TileWidth) - Offset.X;
          Y2 := ((Y - Z + Height + TileHeight - 1) div TileHeight) - Offset.Y;
     end;

     DrawPartialMap(
         Page,
         Offset,
         1, Map.Depth - 1,
         X1, X2,
         Y1, Y2,
         Start
     );
end;


procedure DrawLastColumn(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map.Depth - 1,
         MapCols - 1, MapCols - 1,
         0, MapRows - 1,
         Start
     );
end;

procedure DrawFirstColumn(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map.Depth - 1,
         0, 0,
         0, MapRows - 1,
         Start
     );
end;

procedure DrawLastRow(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map.Depth - 1,
         0, MapCols - 1,
         MapRows - 1, MapRows - 1,
         Start
     );
end;

procedure DrawFirstRow(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         Offset,
         0, Map.Depth - 1,
         0, MapCols - 1,
         0, 0,
         Start
     );
end;


procedure InitTilePositions;
var
   Page, Z, Row, Col: Word;
begin
     for Page := 0 to 1 do begin
         for Row := 0 to MapRows - 1 do begin
             for Col := 0 to MapCols - 1 do begin
                 with TilePositions[Row][Col] do begin
                      X := Col * TileWidth;
                      Y := Row * TileHeight;
                 end;
             end;
         end;
     end;
end;

procedure SaveDirtyRect(Page: Byte; X, Y: Word; var Target: TDirtyRect);
begin
     Target.X := X;
     Target.Y := Y;

     X_CopyToSysMem(
         Page,
         Target.X,
         Target.Y,
         Target.Image^.Width,
         Target.Image^.Height,
         Target.Image^.Data
     );
end;

procedure DrawDirtyRect(Page: Byte; DirtyRect: TDirtyRect);
begin
     X_DrawOpaque(
         Page,
         DirtyRect.X,
         DirtyRect.Y,
         DirtyRect.Image
     );
end;


procedure LoadTiles(Filename: String);
var
   Img: PCXImage;
   i, X, Y: Byte;
begin
     Img.Init(Filename);
     for i := 0 to 255 do begin
         SetColor(i, Img.Palette[i]);
     end;

     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Tiles[Y * 20 + X + 1] := Img.ImageAt(X * 16, Y * 16, 16, 16);
         end;
     end;

     Img.Destroy;
end;

procedure FreeTiles;
var
   X, Y: Byte;
begin
     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Dispose(Tiles[Y * 20 + X + 1], Destroy);
         end;
     end;
end;

procedure R_Init(TilesetFilename: String);
var
   Page: Byte;
begin
     InitTilePositions;

     LoadTiles(TilesetFilename);

     for Page := 0 to 1 do begin
         LastRedraw[Page].X := -1;
         LastRedraw[Page].Y := -1;
     end;
end;

procedure R_AddSprite(Sprite: PSprite);
var
   Page: Byte;
begin
     Sprites[NumSprites] := Sprite;

     for Page := 0 to 1 do begin
         New(DirtyRects[Page][NumSprites].Image, New(Sprite^.Width, Sprite^.Height));
     end;

     Inc(NumSprites);
end;

procedure FreeDirtyRects;
var
   Page, Sprite: Byte;
begin
     for Page := 0 to 1 do begin
         for Sprite := 0 to NumSprites - 1 do begin
             Dispose(DirtyRects[Page][Sprite].Image, Destroy);
         end;
     end;
end;

procedure R_InitScreen;
var
   Offset: TCoordinate;
   Scroll: TCoordinate;
   Page, Sprite: Byte;
begin
     Offset.X := 0;
     Offset.Y := 0;
     Scroll.X := 0;
     Scroll.Y := 0;

     for Page := 0 to 1 do begin
         DrawMap(Page, Offset, 0, MapCols - 1, 0, MapRows - 1, Scroll);

         for Sprite := 0 to NumSprites - 1 do begin
             with Sprites[Sprite]^ do begin
                  SaveDirtyRect(Page, X, Y, DirtyRects[Page][Sprite]);
             end;
         end;
     end;
end;

procedure R_Render(Page: Byte; Scroll: TCoordinate);
var
   NextRedraw: TCoordinate;
   MapRedrawStart: TCoordinate;
   Sprite: Byte;
   DRY: Word;
begin
     for Sprite := 0 to NumSprites - 1 do begin
         DrawDirtyRect(Page, DirtyRects[Page][Sprite]);
     end;

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

     for Sprite := 0 to NumSprites - 1 do begin
         with Sprites[Sprite]^ do begin
              if Z = 65535 then DRY := Y else DRY := Y - Z;

              SaveDirtyRect(Page, X, DRY, DirtyRects[Page][Sprite]);
         end;
     end;

     for Sprite := 0 to NumSprites - 1 do begin
         Sprites[Sprite]^.Draw(Page);
         DrawLayersCoveringSprite(Page, NextRedraw, MapRedrawStart, Sprites[Sprite]);
     end;
end;

procedure R_Destroy;
begin
     FreeDirtyRects;
     FreeTiles;
end;

begin
     NumSprites := 0;
end.