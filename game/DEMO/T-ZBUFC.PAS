{$M 16384, 0, 65535}
program TestZBufferClear;
uses
    Globals,
    Types,
    VGA,
    ModeX,
    PCXImg,
    Debug,
    ZBuf;

procedure ClearScreenAndZBuffer(Page: Byte);
begin
    SetVideoStartAddress(PageOffset[Page], 0);
    ZBuf_Clear;
    X_Fill(0);
end;

procedure TestFirstColumn(Page: Byte);
var
    X, Y: Word;
    Stopwatch: TStopwatch;
begin
    for Y := 0 to LogicalScreenHeight - 1 do begin
        for X := 0 to LogicalScreenWidth - 1 do begin
            X_PutPixelZ(Page, X, Y, (LogicalScreenWidth - X) shr 3, 0);
        end;
    end;

    ZBuf_Draw(Page);

    ReadLn;

    Stopwatch.Init('ZBuf_ClearFirstCol');
    ZBuf_ClearFirstCol(Page);
    Stopwatch.Stop;

    ZBuf_Draw(Page);

    ReadLn;

    SetVideoStartAddress(PageOffset[Page] + 16, 0);

    ReadLn;
end;

procedure TestLastColumn(Page: Byte);
var
    X, Y: Word;
    Stopwatch: TStopwatch;
begin
    for Y := 0 to LogicalScreenHeight - 1 do begin
        for X := 0 to LogicalScreenWidth - 1 do begin
            X_PutPixelZ(Page, X, Y, X shr 3, 0);
        end;
    end;

    ZBuf_Draw(Page);

    ReadLn;

    Stopwatch.Init('ZBuf_ClearLastCol');
    ZBuf_ClearLastCol(Page);
    Stopwatch.Stop;

    ZBuf_Draw(Page);

    ReadLn;

    SetVideoStartAddress(PageOffset[Page] + 16, 0);

    ReadLn;
end;

procedure TestFirstRow(Page: Byte);
var
    X, Y: Word;
    Stopwatch: TStopwatch;
begin
    for Y := 0 to LogicalScreenHeight - 1 do begin
        for X := 0 to LogicalScreenWidth - 1 do begin
            X_PutPixelZ(Page, X, Y, (LogicalScreenHeight - Y) shr 3, 0);
        end;
    end;

    ZBuf_Draw(Page);

    ReadLn;

    Stopwatch.Init('ZBuf_ClearFirstRow');
    ZBuf_ClearFirstRow(Page);
    Stopwatch.Stop;

    ZBuf_Draw(Page);

    ReadLn;

    SetVideoStartAddress(PageOffset[Page] + 32 * PlaneWidth, 0);

    ReadLn;
end;

procedure TestLastRow(Page: Byte);
var
    X, Y: Word;
    Stopwatch: TStopwatch;
begin
    for Y := 0 to LogicalScreenHeight - 1 do begin
        for X := 0 to LogicalScreenWidth - 1 do begin
            X_PutPixelZ(Page, X, Y, Y shr 3, 0);
        end;
    end;

    ZBuf_Draw(Page);

    ReadLn;

    Stopwatch.Init('ZBuf_ClearLastRow');
    ZBuf_ClearLastRow(Page);
    Stopwatch.Stop;

    ZBuf_Draw(Page);

    ReadLn;

    SetVideoStartAddress(PageOffset[Page] + 32 * PlaneWidth, 0);

    ReadLn;
end;

var
    Page: Byte;

begin
    ZBuf_Init;
    InitModeX;
    SetScreenWidth(LogicalScreenWidth);
    SetVideoStartAddress(0, 0);

    for Page := 0 to 1 do begin
        SetVideoStartAddress(PageOffset[Page], 0);

        ClearScreenAndZBuffer(Page);
        TestFirstColumn(Page);

        ClearScreenAndZBuffer(Page);
        TestLastColumn(Page);

        ClearScreenAndZBuffer(Page);
        TestFirstRow(Page);

        ClearScreenAndZBuffer(Page);
        TestLastRow(Page);
    end;

    SetVideoMode(3);
    ZBuf_Destroy;

    PrintProfile;

    ReadLn;
end.
