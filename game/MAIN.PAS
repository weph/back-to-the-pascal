{$R-,S-}
program Main;
uses Crt, IsoMap, VGA, Image, PCXImg, Drivers, Debug, ModeX;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

type
    TDirection = (N, NE, E, SE, S, SW, W, NW);

    TPlayer = object
        X, Y, Z: Integer;
        D: TDirection;
        Speed: Byte;
        PushCycle: Byte;

        procedure Push;
        procedure Update;
    end;


    TCoordinate = record
        X, Y: Integer;
    end;

var
   Map: GameMap;
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;
   Tiles: array[1..255] of PImage;
   PlayerSprites: array[TDirection] of PImage;
   Frame: LongInt;

function HasCollision(X1, Y1, X2, Y2: Word): Boolean;
var
   Tx1, Tx2, Ty1, Ty2: Word;
   X, Y: Word;
begin
     Tx1 := X1 div TileWidth;
     Ty1 := Y1 div TileHeight;
     Tx2 := X2 div TileWidth;
     Ty2 := Y2 div TileHeight;

     for Y := Ty1 to Ty2 do begin
         for X := Tx1 to Tx2 do begin
             if not Map.IsWalkable(X, Y) then begin
                HasCollision := true;
                Exit;
             end;
         end;
     end;

     HasCollision := false;
end;


procedure TPlayer.Push;
begin
     Speed := 3;
     PushCycle := 16;
end;

procedure TPlayer.Update;
var
   Next: TCoordinate;
begin
     Next.X := X;
     Next.Y := Y;

     if (Frame mod 8 = 0) and (Z > 0) then Dec(Z);

     with Next do begin
          case D of
               N: Dec(Y, Speed);
               NE: begin
                   Inc(X, Speed);
                   Dec(Y, Speed);
               end;
               E: Inc(X, Speed);
               SE: begin
                   Inc(X, Speed);
                   Inc(Y, Speed);
               end;
               S: Inc(Y, Speed);
               SW: begin
                   Dec(X, Speed);
                   Inc(Y, Speed);
               end;
               W: Dec(X, Speed);
               NW: begin
                   Dec(X, Speed);
                   Dec(Y, Speed);
               end;
          end;
     end;

     if (Z < 8) and (HasCollision(Next.X + 8, Next.Y + 8, Next.X + 24, Next.Y + 24)) then begin
        Speed := 0;
        Exit;
     end;

     if PushCycle > 0 then begin
        Dec(PushCycle);
     end;

     if (PushCycle = 0) and (Frame mod 2 = 0) and (Speed > 0) then begin
        Dec(Speed);
     end;

     X := Next.X;
     Y := Next.Y;

     if X < 16 then X := 16;
     if Y < 16 then Y := 16;
     if X > (Map.WidthInColumns * TileWidth - 48) then
        X := Map.WidthInColumns * TileWidth - 48;
     if Y > (Map.HeightInRows * TileHeight - 48) then
        Y := Map.HeightInRows * TileHeight - 48;

end;

procedure PutPixel(Page: Byte; ScrollX, ScrollY, X, Y: Word; Color: Byte);
var
   Plane: Byte;
   Dx: Word;
begin
     Dx := (ScrollX + X) div 4;
     Plane := X mod 4;

     SelectPlanes(1 shl Plane);
     Mem[$a000:PageOffset[Page] + (ScrollY + Y) * PlaneWidth + Dx] := Color;
end;

procedure PutChar(Page: Byte; X, Y: Word; C: Char);
var
   Cx, Cy, Mask, Color: Byte;
   Chars: array[0..255*8] of byte absolute $f000:$fa6e;
   Vga: array[0..63999] of byte absolute $a000:$0000;
begin
     for Cy := 0 to 7 do
     begin
          Mask := $80;
          for Cx := 0 to 7 do
          begin
               if Chars[Ord(C) * 8 + Cy] and Mask = Mask then
                   Color := 31
               else
                   Color := 0;

               PutPixel(Page, 0, 0, X + Cx, Y + Cy, Color);

               Mask := Mask shr 1;
          end;
     end;
end;

procedure PutString(Page: Byte; X, Y: Word; S: String);
var
   i: Integer;
begin
     for i := 1 to Length(S) do
         PutChar(Page, X + (i - 1) * 8, Y, S[i]);
end;


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
             {Tiles[Y * 20 + X + 1] := Img.ImageAt(0, 0, 16, 16);}
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

procedure Rect(Page: Byte; ScrollX, ScrollY, X1, Y1, X2, Y2: Word; Color: Byte);
var
   X, Y: Word;
begin
     for X := X1 to X2 do begin
         PutPixel(Page, ScrollX, ScrollY, X, Y1, Color);
         PutPixel(Page, ScrollX, ScrollY, X, Y2, Color);
     end;

     for Y := Y1 to Y2 do begin
         PutPixel(Page, ScrollX, ScrollY, X1, Y, Color);
         PutPixel(Page, ScrollX, ScrollY, X2, Y, Color);
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

procedure MovePlayer(var Player: TPlayer);
var
   Speed: Byte;
   Next: TCoordinate;
begin
     Next.X := Player.X;
     Next.Y := Player.Y;

     if (Frame mod 8 = 0) and (Player.Z > 0) then Dec(Player.Z);

     Speed := Player.Speed;
     with Next do begin
          case Player.D of
               N: Dec(Y, Speed);
               NE: begin
                   Inc(X, Speed);
                   Dec(Y, Speed);
               end;
               E: Inc(X, Speed);
               SE: begin
                   Inc(X, Speed);
                   Inc(Y, Speed);
               end;
               S: Inc(Y, Speed);
               SW: begin
                   Dec(X, Speed);
                   Inc(Y, Speed);
               end;
               W: Dec(X, Speed);
               NW: begin
                   Dec(X, Speed);
                   Dec(Y, Speed);
               end;
          end;
     end;

     if (Player.Z < 8) and (HasCollision(Next.X + 8, Next.Y + 8, Next.X + 24, Next.Y + 24)) then
        Exit;

     Player.X := Next.X;
     Player.Y := Next.Y;

     if Player.X < 16 then Player.X := 16;
     if Player.Y < 16 then Player.Y := 16;
     if Player.X > (Map.WidthInColumns * TileWidth - 48) then
        Player.X := Map.WidthInColumns * TileWidth - 48;
     if Player.Y > (Map.HeightInRows * TileHeight - 48) then
        Player.Y := Map.HeightInRows * TileHeight - 48;

end;

procedure TurnPlayer(var Player: TPlayer; Steps: ShortInt);
var
   Next: ShortInt;
begin
     Next := (Ord(Player.D) + Steps) mod 8;

     if Next < 0 then
        Player.D := TDirection(8 + Next)
     else
         Player.D := TDirection(Next);
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

     ModeXFill(0);
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

           Player.Update;

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

                17: MovePlayer(Player);
                31: MovePlayer(Player);
                32: TurnPlayer(Player, 1);
                30: TurnPlayer(Player, -1);

                $19: Player.Push;
                $39: Player.Z := 16;
           end;

           Inc(Frame);
     end;
end;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     ModeXFill(0);

     LoadPlayer;

     LoadTiles('assets\race.pcx');
     Map.Init('assets\race.map');
     InitTilePositions;

     MainLoop;

     SetVideoMode(3);

     FreeTiles;
end.
