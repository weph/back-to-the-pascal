unit MapRendr;

interface

uses
    Globals,
    Types,
    Image,
    GameMap,
    Sprite,
    Drivers;

type
    TTile = record
        Top: PImage;
        Bottom: PImage;
        Left: PImage;
        Right: PImage;
    end;

    PMapRenderer = ^TMapRenderer;
    TMapRenderer = object
    public
        Map: PGameMap;

        constructor Init(_Map: PGameMap; TilesetFilename: string);
        destructor Destroy;
        procedure Update(Page: Byte; Scroll: TCoordinate);
        procedure Draw(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
        procedure DrawPartialMap(
            Page: Byte;
            Offset: TCoordinate;
            StartLayer, EndLayer: Byte;
            StartCol, EndCol: Word;
            StartRow, EndRow: Word
        ); virtual;

    private
        LastRedraw: array[0..1] of TCoordinate;
        Tiles: array[1..255] of TTile;
    end;

implementation

uses
    PCXImg,
    VGA,
    ModeX,
    Debug,
    ZBuf;

const
    MapCols = LogicalScreenWidth div TileWidth;
    MapRows = LogicalScreenHeight div TileHeight;

var
    TilePositions: array[0..16, 0..MapRows - 1, 0..MapCols - 1] of TCoordinate;

constructor TMapRenderer.Init(_Map: PGameMap; TilesetFilename: string);
var
    Page: Byte;
    Img: PCXImage;
    i: Byte;
begin
    Map := _Map;

    for Page := 0 to 1 do begin
        LastRedraw[Page].X := -1;
        LastRedraw[Page].Y := -1;
    end;

    Img.Init(TilesetFilename);
    for i := 0 to 255 do begin
        SetColor(i, Img.Palette[i]);
    end;

    Tiles[1].Top := Img.ImageAt(0, 0, 32, 8);
    Tiles[1].Bottom := Img.ImageAt(0, 8, 32, 8);
    Tiles[1].Left := Img.ImageAt(0, 0, 16, 16);
    Tiles[1].Right := Img.ImageAt(16, 0, 16, 16);

    Tiles[2].Top := Img.ImageAt(32, 0, 32, 8);
    Tiles[2].Bottom := Img.ImageAt(32, 8, 32, 8);
    Tiles[2].Left := Img.ImageAt(32, 0, 16, 16);
    Tiles[2].Right := Img.ImageAt(48, 0, 16, 16);

    Tiles[3].Top := Img.ImageAt(64, 0, 32, 8);
    Tiles[3].Bottom := Img.ImageAt(64, 8, 32, 16);
    Tiles[3].Left := Img.ImageAt(64, 0, 16, 24);
    Tiles[3].Right := Img.ImageAt(80, 0, 16, 24);

    Tiles[4].Top := Img.ImageAt(96, 0, 32, 8);
    Tiles[4].Bottom := Img.ImageAt(96, 8, 32, 16);
    Tiles[4].Left := Img.ImageAt(96, 0, 16, 24);
    Tiles[4].Right := Img.ImageAt(114, 0, 16, 24);

    Img.Destroy;
end;

destructor TMapRenderer.Destroy;
var
    i: Byte;
begin
    for i := 1 to 4 do begin
        Dispose(Tiles[i].Top);
        Dispose(Tiles[i].Bottom);
        Dispose(Tiles[i].Left);
        Dispose(Tiles[i].Right);
    end;
end;

procedure TMapRenderer.DrawPartialMap(
    Page: Byte;
    Offset: TCoordinate;
    StartLayer, EndLayer: Byte;
    StartCol, EndCol: Word;
    StartRow, EndRow: Word
);
var
    Col, Row, TCol, TRow, Layer: Word;
    CellTiles: TCellTiles;
    Z: Byte;
    SW: TStopwatch;
begin
    if (StartRow = 0) and (EndRow = 0) then begin
        SW.Init('DrawPartialMap');

        for Layer := EndLayer downto StartLayer do begin
            Row := (Layer + 1) div 2;
            TRow := (Offset.Y + Row) shl 1;

            Z := (TRow + Layer);
            if Layer > 0 then
                Inc(Z, Layer);

            for Col := StartCol to EndCol do begin
                with TilePositions[Layer, Row, Col] do begin
                    TCol := Offset.X + Col + 1;
                    Map^.CellTilesAt(TCol, TRow, Layer, CellTiles);

                    if (X < 0) or (Y < 0) then
                        continue;

                    if CellTiles.Bottom <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y + 8, Z + 2, Tiles[CellTiles.Bottom].Top);
                    end;

                    if CellTiles.Right <> 0 then begin
                        X_DrawAlphaZ(Page, X + 16, Y, Z + 1, Tiles[CellTiles.Right].Left);
                    end;

                    if CellTiles.Left <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y, Z + 1, Tiles[CellTiles.Left].Right);
                    end;

                    if CellTiles.Top <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y, Z, Tiles[CellTiles.Top].Bottom);
                    end;
                end;
            end;
        end;

        SW.Stop;
        Exit;
    end;

    SW.Init('DrawPartialMap');

    for Layer := EndLayer downto StartLayer do begin
        for Row := StartRow to EndRow do begin
            TRow := (Offset.Y + Row) shl 1;

            Z := (TRow + Layer);
            if Layer > 0 then
                Inc(Z, Layer);

            for Col := StartCol to EndCol do begin
                with TilePositions[Layer, Row, Col] do begin
                    TCol := Offset.X + Col + 1;
                    Map^.CellTilesAt(TCol, TRow, Layer, CellTiles);

                    if (X < 0) or (Y < 0) then
                        continue;

                    if CellTiles.Bottom <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y + 8, Z + 2, Tiles[CellTiles.Bottom].Top);
                    end;

                    if CellTiles.Right <> 0 then begin
                        X_DrawAlphaZ(Page, X + 16, Y, Z + 1, Tiles[CellTiles.Right].Left);
                    end;

                    if CellTiles.Left <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y, Z + 1, Tiles[CellTiles.Left].Right);
                    end;

                    if CellTiles.Top <> 0 then begin
                        X_DrawAlphaZ(Page, X, Y, Z, Tiles[CellTiles.Top].Bottom);
                    end;
                end;
            end;
        end;
    end;

    SW.Stop;
end;

procedure TMapRenderer.Draw(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
    X_SetScrollOffset(Page, Start);
    DrawPartialMap(Page, Offset, 0, Map^.Depth - 1, 0, MapCols - 1, 0, MapRows - 1);
    LastRedraw[Page] := Start;
end;

procedure TMapRenderer.Update(Page: Byte; Scroll: TCoordinate);
var
    NextRedraw: TCoordinate;
    MapRedrawStart: TCoordinate;
    SW, SWSub: TStopwatch;
begin
    SW.Init('TMapRenderer.Update');
    SW.LogStart;

    NextRedraw.X := Scroll.X div TileWidth;
    NextRedraw.Y := Scroll.Y div TileHeight;
    MapRedrawStart.X := NextRedraw.X * TileWidth;
    MapRedrawStart.Y := NextRedraw.Y * TileHeight;

    X_SetScrollOffset(Page, MapRedrawStart);

    if NextRedraw.X > LastRedraw[Page].X then begin
        SWSub.Init('ZBuf_ClearLastCol');
        ZBuf_ClearLastCol(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, MapCols - 1, MapCols - 1, 0, MapRows - 1);
    end
    else if NextRedraw.X < LastRedraw[Page].X then begin
        SWSub.Init('ZBuf_ClearFirstCol');
        ZBuf_ClearFirstCol(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, 0, 0, MapRows - 1);
    end;

    if NextRedraw.Y > LastRedraw[Page].Y then begin
        SWSub.Init('ZBuf_ClearLastRow');
        ZBuf_ClearLastRow(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, MapCols - 1, MapRows - 1, MapRows - 1);
    end
    else if NextRedraw.Y < LastRedraw[Page].Y then begin
        SWSub.Init('ZBuf_ClearFirstRow');
        ZBuf_ClearFirstRow(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, MapCols - 1, 0, 0);
    end;

    LastRedraw[Page] := NextRedraw;

    SW.Stop;
end;

procedure InitTilePositions;
var
    Col, Row, Layer: Word;
begin
    for Layer := 0 to 16 do begin
        for Col := 0 to MapCols - 1 do begin
            for Row := 0 to MapRows - 1 do begin
                TilePositions[Layer, Row, Col].X := Col * TileWidth;
                TilePositions[Layer, Row, Col].Y := Row * TileHeight - Layer * (TileHeight div 2);
            end;
        end;
    end;
end;

begin
    InitTilePositions;
end.
