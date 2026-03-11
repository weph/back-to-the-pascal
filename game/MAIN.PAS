{$R-,S-}
program Main;
uses Crt, IsoMap, VGA, Image, PCXImg, Drivers, Debug, ModeX, Types, Player;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

var
   Map: GameMap;
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;
   Tiles: array[1..255] of PImage;
   PlayerSprites: array[TDirection] of PImage;
   Frame: LongInt;

function KeyboardScanCode: Byte;
begin
     asm
        mov ah, 01h
        int 16h
        jz @empty

        mov ah, 00h
        int 16h
        jmp @done

     @empty:
        xor ah, ah

     @done:
        mov @Result, ah
     end;
end;

procedure Draw(Page: Byte; X, Y: Integer; Image: PImage);
begin
     if Image^.TransparencyEncoded then
         X_DrawAlpha(Page, X, Y, Image)
     else
         X_Draw16x16Opaque(Page, X, Y, Image);
end;


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
             Tiles[Y * 20 + X + 1]^.TransparencyEncode;
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

procedure LoadPlayer;
var
   Img: PCXImage;
begin
     Img.Init('assets\player.pcx');

     PlayerSprites[S] := Img.ImageAt(0, 0, 32, 32);
     PlayerSprites[S]^.TransparencyEncode;
     PlayerSprites[SW] := Img.ImageAt(32, 0, 32, 32);
     PlayerSprites[SW]^.TransparencyEncode;
     PlayerSprites[W] := Img.ImageAt(64, 0, 32, 32);
     PlayerSprites[W]^.TransparencyEncode;
     PlayerSprites[NW] := Img.ImageAt(96, 0, 32, 32);
     PlayerSprites[NW]^.TransparencyEncode;
     PlayerSprites[N] := Img.ImageAt(128, 0, 32, 32);
     PlayerSprites[N]^.TransparencyEncode;
     PlayerSprites[NE] := Img.ImageAt(160, 0, 32, 32);
     PlayerSprites[NE]^.TransparencyEncode;
     PlayerSprites[E] := Img.ImageAt(192, 0, 32, 32);
     PlayerSprites[E]^.TransparencyEncode;
     PlayerSprites[SE] := Img.ImageAt(224, 0, 32, 32);
     PlayerSprites[SE]^.TransparencyEncode;

     Img.Destroy;
end;

procedure DrawMap(Page: Byte; ColOffset, RowOffset, StartCol, EndCol, StartRow, EndRow: Word; StartX, StartY: Integer);
var
   Z, Col, Row: Word;
   Tile: Byte;
   SW: PStopwatch;
begin
     for Z := 0 to Map.Depth - 1 do begin
         for Row := StartRow to EndRow do begin
             for Col := StartCol to EndCol do begin
                 Tile := Map.TileAt(
                     (ColOffset + Col) mod Map.WidthInColumns,
                     (RowOffset + Row) mod Map.HeightInRows,
                     Z
                 );

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      Draw(Page, StartX + X, StartY + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;

procedure DrawTopLayers(Page: Byte; ColOffset, RowOffset, StartCol, EndCol, StartRow, EndRow: Word; StartX, StartY: Integer);
var
   Z, Col, Row: Word;
   Tile: Byte;
   SW: PStopwatch;
begin
     for Z := 1 to Map.Depth - 1 do begin
         for Row := StartRow to EndRow do begin
             for Col := StartCol to EndCol do begin
                 Tile := Map.TileAt(
                     (ColOffset + Col) mod Map.WidthInColumns,
                     (RowOffset + Row) mod Map.HeightInRows,
                     Z
                 );

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      Draw(Page, StartX + X, StartY + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;


procedure DrawLastColumn(Page: Byte; ColOffset, RowOffset, StartX, StartY: Word);
begin
     DrawMap(Page, ColOffset, RowOffset, MapCols - 1, MapCols - 1, 0, MapRows - 1, StartX, StartY);
end;

procedure DrawFirstColumn(Page: Byte; ColOffset, RowOffset, StartX, StartY: Word);
begin
     DrawMap(Page, ColOffset, RowOffset, 0, 0, 0, MapRows - 1, StartX, StartY);
end;

procedure DrawLastRow(Page: Byte; ColOffset, RowOffset, StartX, StartY: Word);
begin
     DrawMap(Page, ColOffset, RowOffset, 0, MapCols - 1, MapRows - 1, MapRows - 1, StartX, StartY);
end;

procedure DrawFirstRow(Page: Byte; ColOffset, RowOffset, StartX, StartY: Integer);
begin
     DrawMap(Page, ColOffset, RowOffset, 0, MapCols - 1, 0, 0, StartX, StartY);
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

procedure UpdateMapOrigin(var Player: TPlayer; var MapOrigin: TCoordinate);
var
   MaxScrollX, MaxScrollY: Word;
begin
     MaxScrollX := (Map.WidthInColumns * TileWidth) - 320 - 2 * TileWidth;
     MaxScrollY := (Map.HeightInRows * TileHeight) - 240 - 2 * TileHeight;

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

procedure MainLoop;
var
   Running: Boolean;
   Page, NextPage: Byte;
   InitialColOffset, InitialRowOffset, ColOffset, RowOffset: Word;
   RedrawFirst, RedrawLast, RedrawFirstRow, RedrawLastRow: Boolean;
   Scroll: Boolean;
   LastRedrawX, LastRedrawY: Integer;
   NextRedrawX, NextRedrawY: Integer;
   MemPos: String;
   ScrollSpeed: Integer;
   Player: TPlayer;
   MapOrigin: TCoordinate;
   ScrollX, ScrollY: LongInt;
   LastMapOrigin: TCoordinate;
   C: Word;
   Break: Boolean;
   MaxScrollX, MaxScrollY: Word;
   PTileX, PTileY, PTileXE, PTileYE: Integer;
begin
     Frame := 0;
     Running := true;
     Page := 0;
     RedrawFirst := false;
     RedrawLast := false;
     RedrawFirstRow := false;
     RedrawLastRow := false;

     ScrollX := 0;
     ScrollY := 0;
     MaxScrollX := (Map.WidthInColumns * TileWidth) - 320 - TileWidth;
     MaxScrollY := (Map.HeightInRows * TileHeight) - 240 - TileHeight;

     Player.Init(@Map);
     Player.D := S;
     Player.X := 64;
     Player.Y := 16;
     Player.Z := 0;
     Player.Speed := 0;

     UpdateMapOrigin(Player, MapOrigin);

     ColOffset := MapOrigin.X div TileWidth;
     RowOffset := MapOrigin.Y div TileHeight;

     InitialColOffset := ColOffset;
     InitialRowOffset := RowOffset;

     X_Fill(0);
     DrawMap(0, ColOffset, RowOffset, 0, MapCols - 1, 0, MapRows - 1, 0, 0);
     DrawMap(1, ColOffset, RowOffset, 0, MapCols - 1, 0, MapRows - 1, 0, 0);
     SetVideoStartAddress(PageOffset[0] + ScreenOffset, 0);

     LastRedrawX := -1;
     LastRedrawY := -1;

     Scroll := true;
     ScrollSpeed := 1;
     NextPage := Page;
     C := 0;
     Break := false;
     while Running do begin
           NextPage := (Page + 1) and 1;

           LastMapOrigin := MapOrigin;

           PTileX := (Player.X div TileWidth) - NextRedrawX;
           PTileY := ((Player.Y - Player.Z) div TileHeight) - NextRedrawY;
           PTileXE := ((Player.X + 32 + TileWidth - 1) div TileWidth) - NextRedrawX;
           PTileYE := ((Player.Y - Player.Z + 32 + TileHeight - 1) div TileHeight) - NextRedrawY;

           DrawMap(
                   NextPage,
                   ColOffset,
                   RowOffset,
                   PTileX,
                   PTileXE,
                   PTileY,
                   PTileYE,
                   LastRedrawX * TileWidth,
                   LastRedrawY * TileHeight
           );

           {X_DrawRect(
                NextPage,
                NextRedrawX * TileWidth + PTileX * TileWidth,
                NextRedrawY * TileHeight + PTileY * TileHeight,
                NextRedrawX * TileWidth + PTileXE * TileWidth,
                NextRedrawY * TileHeight + PTileYE * TileHeight,
                1
           );}

           Player.Update(Frame);

           UpdateMapOrigin(Player, MapOrigin);

           ScrollX := MapOrigin.X;
           ScrollY := MapOrigin.Y;

           NextRedrawX := ScrollX div TileWidth;
           NextRedrawY := ScrollY div TileHeight;

           ColOffset := InitialColOffset + NextRedrawX;
           RowOffset := InitialRowOffset + NextRedrawY;

           if NextRedrawX <> LastRedrawX then begin
              if NextRedrawX > LastRedrawX then begin
                  DrawLastColumn(NextPage, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
                  RedrawLast := true;
              end else begin
                  DrawFirstColumn(NextPage, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
                  RedrawFirst := true;
              end;

              LastRedrawX := NextRedrawX;
           end;

           if NextRedrawY <> LastRedrawY then begin
              if NextRedrawY > LastRedrawY then begin
                  DrawLastRow(NextPage, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
                  RedrawLastRow := true;
              end else begin
                  DrawFirstRow(NextPage, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
                  RedrawFirstRow := true;
              end;

              LastRedrawY := NextRedrawY;
           end;

           Draw(
                NextPage,
                Player.X,
                Player.Y - Player.Z,
                PlayerSprites[Player.D]
           );

           DrawTopLayers(
                   NextPage,
                   ColOffset,
                   RowOffset,
                   10,
                   10 + 2,
                   7,
                   7 + 2,
                   NextRedrawX * TileWidth,
                   NextRedrawY * TileHeight
           );


           SetVideoStartAddress(
               PageOffset[NextPage] + ScreenOffset + (ScrollY * PlaneWidth) + ScrollX shr 2,
               ScrollX
           );

           if RedrawLast then begin
              DrawLastColumn(Page, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
              RedrawLast := false;
           end;

           if RedrawFirst then begin
              DrawFirstColumn(Page, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
              RedrawFirst := false;
           end;

           if RedrawLastRow then begin
              DrawLastRow(Page, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
              RedrawLastRow := false;
           end;

           if RedrawFirstRow then begin
              DrawFirstRow(Page, ColOffset, RowOffset, NextRedrawX * TileWidth, NextRedrawY * TileHeight);
              RedrawFirstRow := false;
           end;


           Page := NextPage;

           case KeyboardScanCode of
                16: Running := false;
                48: Break := true;

                32: Player.Turn(1);
                30: Player.Turn(-1);

                $19: Player.Push;
                $39: Player.Z := 16;
           end;

           Inc(Frame);
     end;
end;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     X_Fill(0);

     LoadPlayer;

     LoadTiles('assets\race.pcx');
     Map.Init('assets\race.map');
     InitTilePositions;

     MainLoop;

     SetVideoMode(3);

     FreeTiles;
end.
