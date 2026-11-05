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
    PMapRenderer = ^TMapRenderer;
    TMapRenderer = object
    public
        Map: PGameMap;

        constructor Init(_Map: PGameMap);
        procedure Update(Page: Byte; Scroll: TCoordinate);
        procedure Draw(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
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
    ModeX,
    Debug,
    ZBuf;

const
    MapCols = LogicalScreenWidth div TileWidth;
    MapRows = LogicalScreenHeight div TileHeight;

var
    TilePositions: array[0..MapRows - 1, 0..MapCols - 1] of TCoordinate;

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

procedure TMapRenderer.DrawPartialMap;
begin
    RunError;
end;

procedure TMapRenderer.Draw(Page: Byte; Offset: TCoordinate; Start: TCoordinate);
begin
    X_SetScrollOffset(Page, Start);
    DrawPartialMap(Page, Offset, 0, Map^.Depth - 1, 0, MapCols - 1, 0, MapRows - 1, Start);
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

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, MapCols - 1, MapCols - 1, 0, MapRows - 1, MapRedrawStart);
    end
    else if NextRedraw.X < LastRedraw[Page].X then begin
        SWSub.Init('ZBuf_ClearFirstCol');
        ZBuf_ClearFirstCol(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, 0, 0, MapRows - 1, MapRedrawStart);
    end;

    if NextRedraw.Y > LastRedraw[Page].Y then begin
        SWSub.Init('ZBuf_ClearLastRow');
        ZBuf_ClearLastRow(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, MapCols - 1, MapRows - 1, MapRows - 1, MapRedrawStart);
    end
    else if NextRedraw.Y < LastRedraw[Page].Y then begin
        SWSub.Init('ZBuf_ClearFirstRow');
        ZBuf_ClearFirstRow(Page);
        SWSub.Stop;

        DrawPartialMap(Page, NextRedraw, 0, Map^.Depth - 1, 0, MapCols - 1, 0, 0, MapRedrawStart);
    end;

    LastRedraw[Page] := NextRedraw;

    SW.Stop;
end;

end.
