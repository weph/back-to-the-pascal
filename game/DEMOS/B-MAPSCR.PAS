{$M 16384, 0, 131070}
program MapScrollBenchmark;
uses
    Globals,
    VGA,
    ModeX,
    Types,
    Iso,
    Renderer,
    Debug,
    ZBuf;

var
    MapScroll: TCoordinate;
    MapRenderer: TIsometricMapRenderer;
    Page: Byte;
    MaxScrollX: Word;
    SW1, SW2: TStopwatch;

begin
    InitModeX;
    SetScreenWidth(LogicalScreenWidth);
    ZBuf_Init;
    X_Fill(0);

    Page := 0;

    MapScroll.X := 0;
    MapScroll.Y := 0;

    SetVideoStartAddress(PageOffset[Page] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2, MapScroll.X);

    Map.Init('assets\iso2.map');
    MapRenderer.Init(@Map, 'assets\iso2.pcx');
    R_Init(@MapRenderer);

    MaxScrollX := (Map.Width * TileWidth) - 320 - TileWidth;

    R_InitScreen;

    while MapScroll.X < MaxScrollX do begin
        SW1.Init('Frame');
        SW1.LogStart;

        Inc(MapScroll.X);

        R_Render(Page, MapScroll);

        SW2.Init('SetVideoStartAddress');
        SetVideoStartAddress(
            PageOffset[Page] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2,
            MapScroll.X
        );
        SW2.Stop;

        Page := (Page + 1) and 1;

        SW1.Stop;
    end;

    SetVideoMode(3);
    ZBuf_Destroy;
end.
