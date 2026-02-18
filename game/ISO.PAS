program Iso;
uses Dos, Crt, Screen, PCXImg, Sprite, Map, Debug, TETile;

const
     TileWidth = 32;
     TileHeight = 16;

type
    TDirection = (N, NE, E, SE, S, SW, W, NW);
    TTiles = Array[0..2] of PTTile;

    TMapRenderer = object
        Map: PGameMap;
        Screen: PCanvas;
        MapBuffer: PCanvas;
        PrevX, PrevY: Word;
        Tiles: TTiles;
        NumCanvasColumns, NumCanvasRows: Word;
        HalfTileWidth, HalfTileHeight: Word;

        constructor Init(TheMap: PGameMap; TheTiles: TTiles; TheScreen: PCanvas);
        procedure Draw(StartCol, StartRow: Integer);
        procedure DrawTiles(StartCol, EndCol, StartRow, EndRow, ColOffset, RowOffset: Word);
        procedure Update(X, Y: Word);
        procedure BlitToScreen(X, Y: Word);
    end;

constructor TMapRenderer.Init;
begin
     Screen := TheScreen;
     Tiles := TheTiles;

     Map := TheMap;
     MapBuffer := InMemoryCanvas(
         Screen^.CanvasWidth + (TileWidth * 3 div 2),
         Screen^.CanvasHeight + (TileHeight * 3 div 2)
     );
     MapBuffer^.Fill(0);

     HalfTileWidth := TileWidth div 2;
     HalfTileHeight := TileHeight div 2;

     NumCanvasColumns := MapBuffer^.CanvasWidth div TileWidth;
     NumCanvasRows := MapBuffer^.CanvasHeight div (TileHeight div 2);
end;

procedure TMapRenderer.Draw;
var
   WidthInTiles: Word;
   HeightInTiles: Word;
begin
     WidthInTiles := MapBuffer^.CanvasWidth div TileWidth;
     HeightInTiles := MapBuffer^.CanvasHeight div (TileHeight div 2);

     DrawTiles(StartCol, StartCol + WidthInTiles, StartRow, StartRow + HeightInTiles, 0, 0);
end;

type
    PUpdateInfo = ^UpdateInfo;
    UpdateInfo = record
        Src, Dst, CopySize: Integer;
        StartTile: Integer;
        TileOffset: Integer;
        NumTilesStart: Integer;
        NumTilesEnd: Integer;
        NeedsRedraw: Boolean;
    end;

function UpdateInfoFor(Prev, Next, ScreenSize, BufferSize, TileSize: Integer): PUpdateInfo;
var
   PrevStartTile, NextStartTile: Integer;
   PrevScroll, NextScroll: Integer;
   CopyOffset: Integer;
   Result: PUpdateInfo;
begin
     New(Result);

     PrevStartTile := Prev div TileSize;
     NextStartTile := Next div TileSize;

     PrevScroll := Prev mod TileSize;

     CopyOffset := Abs(NextStartTile - PrevStartTile) * TileSize;

     if Prev < Next then
     begin
          Result^.Src := CopyOffset - PrevScroll;
          Result^.Dst := 0;
     end
     else
     begin
          Result^.Src := -PrevScroll;
          Result^.Dst := CopyOffset;
     end;

     if Result^.Src < 0 then
     begin
          Inc(Result^.Src, TileSize);
          Inc(Result^.Dst, TileSize);
     end;

     Result^.CopySize := ScreenSize - Result^.Src;
     {Dec(Result^.CopySize, Result^.CopySize mod TileSize);}

     if (Result^.Dst + Result^.CopySize > BufferSize) then
        Result^.CopySize := BufferSize - Result^.Dst;

     Result^.StartTile := NextStartTile;
     Result^.NumTilesStart := Result^.Dst div TileSize;
     Result^.NumTilesEnd := (BufferSize - Result^.Dst - Result^.CopySize) div TileSize;
     Result^.NeedsRedraw := PrevStartTile <> NextStartTile;

     UpdateInfoFor := Result;
end;


function UpdateInfoForY(Prev, Next, ScreenSize, BufferSize, TileSize: Integer): PUpdateInfo;
var
   PrevStartTile, NextStartTile: Integer;
   PrevScroll, NextScroll: Integer;
   CopyOffset: Integer;
   Result: PUpdateInfo;
begin
     New(Result);

     PrevStartTile := Prev div TileSize;
     NextStartTile := Next div TileSize;

     PrevScroll := Prev mod TileSize;

     CopyOffset := Abs(NextStartTile - PrevStartTile) * TileSize;

     if Prev < Next then
     begin
          Result^.Src := CopyOffset - PrevScroll;
          Result^.Dst := 0;
     end
     else
     begin
          Result^.Src := -PrevScroll;
          Result^.Dst := CopyOffset;
     end;

     if Result^.Src < 0 then
     begin
          Inc(Result^.Src, TileSize);
          Inc(Result^.Dst, TileSize);
     end;

     Result^.CopySize := ScreenSize - Result^.Src;
     {Dec(Result^.CopySize, Result^.CopySize mod TileSize);}

     if (Result^.Dst + Result^.CopySize > BufferSize) then
        Result^.CopySize := BufferSize - Result^.Dst;

     Result^.StartTile := (Next div (TileSize shr 1));
     Result^.NumTilesStart := Result^.Dst div TileSize;
     Result^.NumTilesEnd := (BufferSize - Result^.Dst - Result^.CopySize) div TileSize;
     Result^.NeedsRedraw := PrevStartTile <> NextStartTile;

     UpdateInfoForY := Result;
end;

procedure TMapRenderer.Update;
var
   XInfo, YInfo: PUpdateInfo;
   XColumns: LongInt;
begin
     if (X = PrevX) and (Y = PrevY) then
        Exit;

     XInfo := UpdateInfoFor(PrevX, X, Screen^.CanvasWidth, MapBuffer^.CanvasWidth, TileWidth);
     YInfo := UpdateInfoForY(PrevY, Y, Screen^.CanvasHeight, MapBuffer^.CanvasHeight, TileHeight);

     if (XInfo^.NeedsRedraw) or (YInfo^.NeedsRedraw) then
     begin
          {MapBuffer^.Fill(0);}

          Screen^.CopyAreaTo(
             XInfo^.Src, YInfo^.Src,
             XInfo^.CopySize, YInfo^.CopySize,
             MapBuffer,
             XInfo^.Dst + HalfTileWidth, YInfo^.Dst + HalfTileHeight
         );

         {MapBuffer^.Fill(0);}

         if XInfo^.NumTilesStart > 0 then
            DrawTiles(
                0,
                XInfo^.NumTilesStart - 1,
                0,
                NumCanvasRows - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );

         if XInfo^.NumTilesEnd > 0 then
            DrawTiles(
                NumCanvasColumns - XInfo^.NumTilesEnd,
                NumCanvasColumns,
                0,
                NumCanvasRows - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );

         if YInfo^.NumTilesStart > 0 then
            DrawTiles(
                0,
                NumCanvasColumns - 1,
                0,
                YInfo^.NumTilesStart - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
         );


         if YInfo^.NumTilesEnd > 0 then
            DrawTiles(
                0,
                NumCanvasColumns - 1,
                NumCanvasRows - YInfo^.NumTilesEnd - 3,
                NumCanvasRows - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );
     end;

     BlitToScreen(X, Y);

     Dispose(XInfo);
     Dispose(YInfo);
end;

procedure TMapRenderer.DrawTiles;
var
   Col, Row, Tile, X, Y: Word;
begin
     for Row := StartRow to EndRow do
         for Col := StartCol to EndCol do
         begin
              Tile := Map^.TileAt(Col + ColOffset, Row + RowOffset);
              if Tile = 255 then
                 Exit;

              X := Col * TileWidth + ((Row + RowOffset) mod 2) * HalfTileWidth;
              Y := Row * HalfTileHeight;

              MapBuffer^.DrawEncoded(X, Y, Tiles[Tile]);
         end;
end;

procedure TMapRenderer.BlitToScreen;
var
   Sx, Sy: Word;
begin
     Sx := (X mod TileWidth) + (TileWidth div 2);
     Sy := (Y mod TileHeight) + (TileHeight div 2);

     MapBuffer^.CopyAreaTo(
         Sx,
         Sy,
         Screen^.CanvasWidth,
         Screen^.CanvasHeight,
         Screen,
         0, 0
     );

     PrevX := X;
     PrevY := Y;
end;

procedure Rectangle(Canvas: PCanvas; X1, X2, Y1, Y2: Word);
var
   X, Y: Word;
begin
     for X := X1 to X2 do
     begin
          Canvas^.PutPixel(X, Y1, 10);
          Canvas^.PutPixel(X, Y2, 10);
     end;

     for Y := Y1 to Y2 do
     begin
          Canvas^.PutPixel(X1, Y, 10);
          Canvas^.PutPixel(X2, Y, 10);
     end;
end;

function ColoredTile(Image: PCXImage; Offset: Word): Pointer;
var
   Result: PChar;
   Size, i: Word;
   NewValue: Char;
begin
     Size := Image.Width * Image.Height;
     GetMem(Result, Size);

     for i := 0 to Size - 1 do
     begin
         if Ord(Image.Data[i]) = 0 then
            NewValue := Chr(0)
         else
             NewValue := Chr(Ord(Image.Data[i]) + Offset);

         Result[i] := NewValue;
     end;

     ColoredTile := New(PTTile, From(Result, TileWidth, TileHeight));
end;

function Timestamp: LongInt;
var
   Hour, Min, Sec, Sec100: Word;
begin
     GetTime(Hour, Min, Sec, Sec100);

     Timestamp := LongInt(Hour) * 360000 +
        LongInt(Min) * 6000 +
        LongInt(Sec) * 100 +
        LongInt(Sec100);
end;


var
   Video: PCanvas;
   VScreen: PCanvas;
   X, Y: Word;
   Running: Boolean;
   FPS: FPSInfo;
   TheMap: GameMap;
   MapRenderer: TMapRenderer;
   DestX, DestY: Word;
   StartColumn, StartRow: Integer;
   Tile: PCXImage;
   Tiles: TTiles;
   Start: LongInt;
   Delta: LongInt;

begin
     FPS.Init(10);

     Video := DoubleBufferedVGACanvas;
     Video^.Fill(0);

     VScreen := InMemoryCanvas(256, 128);

     Tile.Init('tile.pcx');
     New(Tiles[0], From(Tile.Data, TileWidth, TileHeight));
     Tiles[1] := ColoredTile(Tile, 2);
     Tiles[2] := ColoredTile(Tile, 4);

     TheMap.Init('map.txt');
     MapRenderer.Init(@TheMap, Tiles, Video);

     X := 0;
     Y := 0;

     Running := True;

     DestX := (Video^.CanvasWidth - VScreen^.CanvasWidth) shr 1;
     DestY := (Video^.CanvasHeight - VScreen^.CanvasHeight) shr 1;

     StartColumn := 0;
     StartRow := 0;
     MapRenderer.Draw(StartColumn, StartRow);
     while Running do
     begin
          {Start := Timestamp;}
          FPS.Update;
          FPS.Show;

          {StartColumn := x div TileWidth;

          if StartColumn < 0 then
             StartColumn := 0;

          if StartRow < 0 then
             StartRow := 0;}

          {MapRenderer.Draw(StartColumn, StartRow);
          MapRenderer.BlitToScreen(X, Y);}
          MapRenderer.Update(X, Y);

          {Video^.Fill(0);}
          {VScreen^.CopyAreaTo(0, 0, VScreen^.CanvasWidth, VScreen^.CanvasHeight, Video, DestX, DestY);}
          {MapRenderer.MapBuffer^.CopyAreaTo(
              X mod TileWidth + TileWidth div 2,
              Y mod TileHeight + TileHeight div 2,
              MapRenderer.MapBuffer^.CanvasWidth - X mod TileWidth - TileWidth div 2,
              MapRenderer.MapBuffer^.CanvasHeight - Y mod TileHeight - TileHeight div 2,
              Video,
              DestX,
              DestY
          );

          Rectangle(Video, DestX, DestX + VScreen^.CanvasWidth, DestY, DestY + VScreen^.CanvasHeight);}

          Video^.Update;

          Inc(X);
          {Inc(Y);}

          if KeyPressed then
             case ReadKey of
                  'q': Running := false;
                  's': begin
                       Inc(Y);
                  end;
                  'w': begin
                       Dec(Y);
                  end;

                  'a': begin
                       Dec(X);
                  end;
                  'd': begin
                       Inc(X);
                  end;
             end;

          {Delta := Timestamp - Start;
          if Delta < 15 then
             Delay(15 - Delta);}
     end;

     Tile.Destroy;
     Dispose(MapRenderer.MapBuffer);
     Dispose(Video, Destroy);
end.