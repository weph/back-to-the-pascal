program MapScrollBenchmark;
uses Globals, VGA, ModeX, Types, Iso, Renderer, Debug;

var
   MapScroll: TCoordinate;
   MapRenderer: TIsometricMapRenderer;
   Page: Byte;
   MaxScrollX: Word;

begin
    InitModeX;
    SetScreenWidth(LogicalScreenWidth);
    X_InitZBuf;
    X_Fill(0);

    Page := 0;

    MapScroll.X := 0;
    MapScroll.Y := 0;

    SetVideoStartAddress(
        PageOffset[Page] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2,
        MapScroll.X
    );

    Map.Init('assets\iso2.map');
    MapRenderer.Init(@Map, 'assets\iso2.pcx');
    R_Init(@MapRenderer);

    MaxScrollX := (Map.Width * TileWidth) - 320 - TileWidth;

    R_InitScreen;

    while MapScroll.X < MaxScrollX do begin
          Inc(MapScroll.X);

          R_Render(Page, MapScroll);

          SetVideoStartAddress(
              PageOffset[Page] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2,
              MapScroll.X
          );

          Page := (Page + 1) and 1;
    end;

    SetVideoMode(3);

    Profiler^.Write('B-MAPSCR.TXT');
end.