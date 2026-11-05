{$M 16384, 0, 131070}
program DrawBenchmark;
uses
    Globals,
    VGA,
    ModeX,
    Zentimer,
    PCXImg,
    Image,
    Debug,
    Drivers,
    ZBuf;

type
    TDrawFunc = procedure(Page: Byte; X, Y: Word; Image: PImage);
    TDrawZFunc = procedure(Page: Byte; X, Y: Word; Z: Byte; Image: PImage);

const
    Cols = LogicalScreenWidth div TileWidth;
    Rows = LogicalScreenHeight div TileHeight;
    Iterations = 5;

procedure RunBenchmark(Title: string; Draw: TDrawFunc; Tile: PImage);
var
    i: Byte;
    Stopwatch: TStopwatch;
    Num: string;
    Row, Col: Word;
begin
    for i := 0 to Iterations - 1 do begin
        X_Fill(7);

        Str(i, Num);

        Stopwatch.Init(Title + ' #' + Num);

        for Row := 0 to Rows - 1 do begin
            for Col := 0 to Cols - 1 do begin
                Draw(0, Col * TileWidth, Row * TileHeight, Tile);
            end;
        end;

        Stopwatch.Stop;
    end;

    ReadLn;
end;

procedure RunBenchmarkZ(Title: string; Draw: TDrawZFunc; Tile: PImage);
var
    i: Byte;
    Stopwatch: TStopwatch;
    Num: string;
    Row, Col: Word;
begin
    for i := 0 to Iterations - 1 do begin
        X_Fill(7);
        ZBuf_Clear;

        Str(i, Num);

        Stopwatch.Init(Title + ' #' + Num);

        for Row := 0 to Rows - 1 do begin
            for Col := 0 to Cols - 1 do begin
                Draw(0, Col * TileWidth, Row * TileHeight, 255, Tile);
            end;
        end;

        Stopwatch.Stop;
    end;

    ReadLn;
end;

var
    SourceImage: PCXImage;
    TileOpaque, TileAlpha: PImage;

begin
    InitModeX;
    ZBuf_Init;
    SetScreenWidth(LogicalScreenWidth);
    SetVideoStartAddress(0, 0);

    SourceImage.Init('demos\b-draw.pcx');

    TileOpaque := SourceImage.ImageAt(0, 0, 16, 16);
    TileAlpha := SourceImage.ImageAt(16, 0, 16, 16);

    RunBenchmark('X_DrawOpaque', X_DrawOpaque, TileOpaque);
    RunBenchmarkZ('X_DrawAlpha', X_DrawAlpha, TileAlpha);
    RunBenchmarkZ('X_DrawAlphaZ', X_DrawAlphaZ, TileAlpha);

    SetVideoMode(3);
    ZBuf_Destroy;

    PrintProfile;

    ReadLn;
end.
