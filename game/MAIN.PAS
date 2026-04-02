{$R-,S-}
program Main;
uses
    Crt,
    GameMap,
    VGA,
    Image,
    PCXImg,
    Drivers,
    Debug,
    ModeX,
    Types,
    Player,
    Keyboard,
    Malloc;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

var
   Map: TGameMap;
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;
   Tiles: array[1..255] of PImage;
   Frame: LongInt;

procedure LoadTiles(Filename: String);
var
   Img: PCXImage;
   i, j: Byte;
   X, Y: Byte;
   S: String;
   P: array[0..0] of Longint;
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

procedure DrawPartialMap(
    Page: Byte;
    ColOffset, RowOffset: Word;
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
                 Tile := Map.TileAt(ColOffset + Col, RowOffset + Row, Z);

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      X_Draw(Page, Start.X + X, Start.Y + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;

procedure DrawMap(Page: Byte; ColOffset, RowOffset, StartCol, EndCol, StartRow, EndRow: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
         0, Map.Depth - 1,
         StartCol, EndCol,
         StartRow, EndRow,
         Start
     );
end;

procedure DrawTopLayers(Page: Byte; ColOffset, RowOffset, StartCol, EndCol, StartRow, EndRow: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
         1, Map.Depth - 1,
         StartCol, EndCol,
         StartRow, EndRow,
         Start
     );
end;


procedure DrawLastColumn(Page: Byte; ColOffset, RowOffset: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
         0, Map.Depth - 1,
         MapCols - 1, MapCols - 1,
         0, MapRows - 1,
         Start
     );
end;

procedure DrawFirstColumn(Page: Byte; ColOffset, RowOffset: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
         0, Map.Depth - 1,
         0, 0,
         0, MapRows - 1,
         Start
     );
end;

procedure DrawLastRow(Page: Byte; ColOffset, RowOffset: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
         0, Map.Depth - 1,
         0, MapCols - 1,
         MapRows - 1, MapRows - 1,
         Start
     );
end;

procedure DrawFirstRow(Page: Byte; ColOffset, RowOffset: Word; Start: TCoordinate);
begin
     DrawPartialMap(
         Page,
         ColOffset, RowOffset,
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

procedure UpdateMapScroll(var Player: TPlayer; var MapOrigin: TCoordinate);
var
   MaxScrollX, MaxScrollY: Word;
begin
     MaxScrollX := (Map.Width * TileWidth) - 320 - 2 * TileWidth;
     MaxScrollY := (Map.Height * TileHeight) - 240 - 2 * TileHeight;

     if Player.X < 160 then
         MapOrigin.X := 0
     else if (Player.X - 160) > MaxScrollX then
         MapOrigin.X := MaxScrollX
     else
         MapOrigin.X := Player.X - 160;

     if Player.Y < 120 then
         MapOrigin.Y := 0
     else if (Player.Y - 120) > MaxScrollY then
         MapOrigin.Y := MaxScrollY
     else
         MapOrigin.Y := Player.Y - 120;
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

procedure MainLoop;
var
   Running: Boolean;
   Page, NextPage: Byte;
   InitialColOffset, InitialRowOffset, ColOffset, RowOffset: Word;
   Scroll: Boolean;
   LastRedraw: array[0..1] of TCoordinate;
   NextRedraw: TCoordinate;
   MemPos: String;
   ScrollSpeed: Integer;
   Player: TPlayer;
   MapScroll: TCoordinate;
   MapRedrawStart: TCoordinate;
   C: Word;
   Break: Boolean;
   MaxScrollX, MaxScrollY: Word;
   PTileX, PTileY, PTileXE, PTileYE: Integer;
   FPS: FPSInfo;
   FpsString: String;
   FpsBackground: array[0..1] of TDirtyRect;
begin
     FPS.Init(60);
     New(FpsBackground[0].Image, New(48, 16));
     New(FpsBackground[1].Image, New(48, 16));

     Frame := 0;
     Running := true;
     Page := 0;

     MaxScrollX := (Map.Width * TileWidth) - 320 - TileWidth;
     MaxScrollY := (Map.Height * TileHeight) - 240 - TileHeight;

     Player.Init(@Map, 'assets\player.pcx');
     Player.D := S;
     Player.X := 16;
     Player.Y := 16;

     UpdateMapScroll(Player, MapScroll);

     ColOffset := MapScroll.X div TileWidth;
     RowOffset := MapScroll.Y div TileHeight;

     InitialColOffset := ColOffset;
     InitialRowOffset := RowOffset;

     X_Fill(0);
     MapRedrawStart.X := 0;
     MapRedrawStart.Y := 0;
     DrawMap(0, ColOffset, RowOffset, 0, MapCols - 1, 0, MapRows - 1, MapRedrawStart);
     DrawMap(1, ColOffset, RowOffset, 0, MapCols - 1, 0, MapRows - 1, MapRedrawStart);
     SetVideoStartAddress(PageOffset[0] + ScreenOffset, 0);

     for Page := 0 to 1 do begin
         LastRedraw[Page].X := -1;
         LastRedraw[Page].Y := -1;

         SaveDirtyRect(Page, Player.X, Player.Y, Player.DirtyRect[Page]);

         SaveDirtyRect(Page, 0, 0, FpsBackground[Page]);
     end;

     Page := 0;
     Scroll := true;
     ScrollSpeed := 1;
     NextPage := Page;
     C := 0;
     Break := false;
     while Running do begin
           FPS.Update;

           NextPage := (Page + 1) and 1;

           DrawDirtyRect(NextPage, Player.DirtyRect[NextPage]);

           Player.Update(Frame);

           UpdateMapScroll(Player, MapScroll);

           DrawDirtyRect(NextPage, FpsBackground[NextPage]);
           SaveDirtyRect(NextPage, MapScroll.X + 16, MapScroll.Y + 16, FpsBackground[NextPage]);
           Str(FPS.CurrentFps:0:3, FpsString);
           X_PutString(NextPage, MapScroll.X + 16, MapScroll.Y + 16, FpsString);

           NextRedraw.X := MapScroll.X div TileWidth;
           NextRedraw.Y := MapScroll.Y div TileHeight;
           MapRedrawStart.X := NextRedraw.X * TileWidth;
           MapRedrawStart.Y := NextRedraw.Y * TileHeight;

           ColOffset := InitialColOffset + NextRedraw.X;
           RowOffset := InitialRowOffset + NextRedraw.Y;

           if NextRedraw.X > LastRedraw[NextPage].X then begin
               DrawLastColumn(NextPage, ColOffset, RowOffset, MapRedrawStart);
           end else if NextRedraw.X < LastRedraw[NextPage].X then begin
               DrawFirstColumn(NextPage, ColOffset, RowOffset, MapRedrawStart);
           end;

           LastRedraw[NextPage].X := NextRedraw.X;

           if NextRedraw.Y > LastRedraw[NextPage].Y then begin
               DrawLastRow(NextPage, ColOffset, RowOffset, MapRedrawStart);
           end else if NextRedraw.Y < LastRedraw[NextPage].Y then begin
               DrawFirstRow(NextPage, ColOffset, RowOffset, MapRedrawStart);
           end;

           LastRedraw[NextPage].Y := NextRedraw.Y;

           SaveDirtyRect(NextPage, Player.X, Player.Y - Player.Z, Player.DirtyRect[NextPage]);

           X_Draw(
                NextPage,
                Player.X,
                Player.Y - Player.Z,
                Player.Sprites[Player.D]
           );

           PTileX := (Player.X div TileWidth) - NextRedraw.X;
           PTileY := ((Player.Y - Player.Z) div TileHeight) - NextRedraw.Y;
           PTileXE := ((Player.X + 32 + TileWidth - 1) div TileWidth) - NextRedraw.X;
           PTileYE := ((Player.Y - Player.Z + 32 + TileHeight - 1) div TileHeight) - NextRedraw.Y;

           DrawTopLayers(
                   NextPage,
                   ColOffset,
                   RowOffset,
                   PTileX,
                   PTileXE,
                   PTileY,
                   PTileYE,
                   MapRedrawStart
           );


           SetVideoStartAddress(
               PageOffset[NextPage] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2,
               MapScroll.X
           );

           Page := NextPage;

           if Keys[$10] then Running := False;
           if Keys[$1e] then Player.Turn(Frame, -1);
           if Keys[$20] then Player.Turn(Frame, 1);
           if Keys[$19] then Player.Push;
           if Keys[$39] then Player.Ollie;

           Inc(Frame);
     end;

     Dispose(FpsBackground[0].Image, Destroy);
     Dispose(FpsBackground[1].Image, Destroy);
     Player.Destroy;
end;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     X_Fill(0);

     LoadTiles('assets\race2.pcx');
     Map.Init('assets\race2.map');
     InitTilePositions;

     MainLoop;

     SetVideoMode(3);

     Map.Destroy;
     FreeTiles;

     Profiler^.Print;
     M_Debug;
end.
