unit MapRendr;

interface

uses
    Globals,
    Types,
    Image,
    GameMap,
    Sprite;

type
    PMapRenderer = ^TMapRenderer;
    TMapRenderer = object
        public
            Map: PGameMap;

            constructor Init(_Map: PGameMap);
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
            procedure DrawPartialMap(
                Page: Byte;
                Offset: TCoordinate;
                StartLayer, EndLayer: Byte;
                StartCol, EndCol: Word;
                StartRow, EndRow: Word;
                Start: TCoordinate
            ); virtual;

        private
            LastRedraw: array[0..1] of TCoordinate;
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

constructor TMapRenderer.Init(_Map: PGameMap);
var
   Page: Byte;
begin
     Map := _Map;

     for Page := 0 to 1 do begin
         LastRedraw[Page].X := -1;
         LastRedraw[Page].Y := -1;
     end;
end;

procedure TMapRenderer.DrawPartialMap(
    Page: Byte;
    Offset: TCoordinate;
    StartLayer, EndLayer: Byte;
    StartCol, EndCol: Word;
    StartRow, EndRow: Word;
    Start: TCoordinate
);
begin
     RunError;
end;

procedure TMapRenderer.Draw(
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

procedure TMapRenderer.DrawLayersCoveringSprite(
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

procedure TMapRenderer.Update(Page: Byte; Scroll: TCoordinate);
var
   NextRedraw: TCoordinate;
   MapRedrawStart: TCoordinate;
begin
     NextRedraw.X := Scroll.X div TileWidth;
     NextRedraw.Y := Scroll.Y div TileHeight;
     MapRedrawStart.X := NextRedraw.X * TileWidth;
     MapRedrawStart.Y := NextRedraw.Y * TileHeight;

     if NextRedraw.X > LastRedraw[Page].X then begin
         DrawPartialMap(
             Page,
             NextRedraw,
             0, Map^.Depth - 1,
             MapCols - 1, MapCols - 1,
             0, MapRows - 1,
             MapRedrawStart
         );
     end else if NextRedraw.X < LastRedraw[Page].X then begin
         DrawPartialMap(
             Page,
             NextRedraw,
             0, Map^.Depth - 1,
             0, 0,
             0, MapRows - 1,
             MapRedrawStart
         );
     end;

     if NextRedraw.Y > LastRedraw[Page].Y then begin
         DrawPartialMap(
             Page,
             NextRedraw,
             0, Map^.Depth - 1,
             0, MapCols - 1,
             MapRows - 1, MapRows - 1,
             MapRedrawStart
         );
     end else if NextRedraw.Y < LastRedraw[Page].Y then begin
         DrawPartialMap(
             Page,
             NextRedraw,
             0, Map^.Depth - 1,
             0, MapCols - 1,
             0, 0,
             MapRedrawStart
         );
     end;

     LastRedraw[Page] := NextRedraw;
end;

end.