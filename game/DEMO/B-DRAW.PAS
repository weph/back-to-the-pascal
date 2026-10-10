program DrawBenchmark;
uses
    Globals,
    VGA,
    ModeX,
    Zentimer,
    PCXImg,
    Image,
    Debug,
    Drivers;

type
    TDrawFunc = procedure(Page: Byte; X, Y: Word; Image: PImage);
    TDrawZFunc = procedure(Page: Byte; X, Y: Word; Z: Byte; Image: PImage);

const
    Cols = LogicalScreenWidth div TileWidth;
    Rows = LogicalScreenHeight div TileHeight;
    Iterations = 5;

var
    Profiler: TProfiler;

procedure RunBenchmark(Title: string; Draw: TDrawFunc; Tile: PImage);
var
    i: Byte;
    Stopwatch: PStopwatch;
    Num: string;
    Row, Col: Word;
begin
    for i := 0 to Iterations - 1 do begin
        X_Fill(7);

        Str(i, Num);

        Stopwatch := Profiler.Stopwatch(Title + ' #' + Num);
        Stopwatch^.Start;

        for Row := 0 to Rows - 1 do begin
            for Col := 0 to Cols - 1 do begin
                Draw(0, Col * TileWidth, Row * TileHeight, Tile);
            end;
        end;

        Stopwatch^.Stop;
    end;

    ReadLn;
end;

procedure RunBenchmarkZ(Title: string; Draw: TDrawZFunc; Tile: PImage);
var
    i: Byte;
    Stopwatch: PStopwatch;
    Num: string;
    Row, Col: Word;
begin
    for i := 0 to Iterations - 1 do begin
        X_Fill(7);
        X_ClearZBuf(0);

        Str(i, Num);

        Stopwatch := Profiler.Stopwatch(Title + ' #' + Num);
        Stopwatch^.Start;

        for Row := 0 to Rows - 1 do begin
            for Col := 0 to Cols - 1 do begin
                Draw(0, Col * TileWidth, Row * TileHeight, 255, Tile);
            end;
        end;

        Stopwatch^.Stop;
    end;

    ReadLn;
end;

var
    SourceImage: PCXImage;
    TileOpaque, TileAlpha: PImage;

begin
    Profiler.Init;

    InitModeX;
    X_InitZBuf;
    SetScreenWidth(LogicalScreenWidth);
    SetVideoStartAddress(0, 0);

    SourceImage.Init('demo\b-draw.pcx');

    TileOpaque := SourceImage.ImageAt(0, 0, 16, 16);
    TileAlpha := SourceImage.ImageAt(16, 0, 16, 16);

    RunBenchmark('X_DrawOpaque', X_DrawOpaque, TileOpaque);
    RunBenchmark('X_Draw16x16Opaque', X_Draw16x16Opaque, TileOpaque);
    RunBenchmarkZ('X_DrawAlpha', X_DrawAlpha, TileAlpha);
    RunBenchmarkZ('X_DrawAlphaZ', X_DrawAlphaZ, TileAlpha);

    SetVideoMode(3);
    X_DestroyZBuf;

    Profiler.Print;

    ReadLn;
end.
