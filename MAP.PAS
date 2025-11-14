unit Map;

interface

uses Screen, PcxImg;

const
    MaxWidth = 200;
    MaxHeight = 100;

type
    PGameMap = ^GameMap;
    GameMap = object
            private
                WidthInColumns, HeightInRows: Word;
                Screen: PCanvas;
                MapCanvas: Buffer;
                NumCanvasColumns, NumCanvasRows: Word;
                Data: Array[0..MaxWidth * MaxHeight] of Byte;
                Tile: Array[0..6] of PChar;
                PrevX, PrevY: Word;

                procedure DrawTiles(StartCol, EndCol, StartRow, EndRow, ColOffset, RowOffset: Word);
                procedure BlitToScreen(X, Y: Word);
            public
                Width, Height: Word;
                TileWidth, TileHeight: Word;

                constructor Init(Filename: String; TheScreen: PCanvas; TWidth, THeight: Word);
                function TileAt(X, Y: Word): Byte;
                function NextGroundYAt(XLeft, XRight, Y: Word): Word;
                procedure Draw(X, Y: Word);
                procedure Update(X, Y: Word);
    end;


implementation

uses Crt;

constructor GameMap.Init;
var
   MapFile: Text;
   Line: String;
   X, Y: Word;
   TilesImage: ^PcxImage;
begin
     Screen := TheScreen;

     TileWidth := TWidth;
     TileHeight := THeight;

     MapCanvas.Init(Screen^.CanvasWidth + TileWidth, Screen^.CanvasHeight + TileHeight);
     NumCanvasColumns := MapCanvas.CanvasWidth div TileWidth;
     NumCanvasRows := MapCanvas.CanvasHeight div TileHeight;

     MapCanvas.Fill(0);

     Assign(MapFile, 'map.txt');
     Reset(MapFile);

     Y := 0;

     while not Eof(MapFile) do
     begin
          ReadLn(MapFile, Line);

          if Y = 0 then
             WidthInColumns := Length(Line);

          for X := 1 to Length(Line) do
              Data[Y * WidthInColumns + X - 1] := Ord(Line[X]) - Ord('0');

          Inc(Y);
     End;

     HeightInRows := Y;

     Width := WidthInColumns * TileWidth;
     Height := HeightInRows * TileHeight;

     Close(MapFile);

     New(TilesImage, Init('img\tiles.pcx'));
     Tile[0] := TilesImage^.SpriteAt(0, 0, TileWidth, TileHeight);
     Tile[1] := TilesImage^.SpriteAt(0, 8, TileWidth, TileHeight);
     Tile[2] := TilesImage^.SpriteAt(8, 8, TileWidth, TileHeight);
     Tile[3] := TilesImage^.SpriteAt(16, 8, TileWidth, TileHeight);
     Tile[4] := TilesImage^.SpriteAt(24, 8, TileWidth, TileHeight);
     Tile[5] := TilesImage^.SpriteAt(32, 8, TileWidth, TileHeight);
     Tile[6] := TilesImage^.SpriteAt(40, 8, TileWidth, TileHeight);
end;

function GameMap.TileAt(X, Y: Word): Byte;
begin
     TileAt := Data[Y * WidthInColumns + X]
end;

function GameMap.NextGroundYAt(XLeft, XRight, Y: Word): Word;
var
   Txl, Txr, Ty: Byte;
begin
     Txl := XLeft div TileWidth;
     Txr := XRight div TileWidth;
     Ty := Y div TileHeight;

     NextGroundYAt := HeightInRows * TileHeight + 32;

     while Ty < HeightInRows do
     begin
          if (TileAt(Txl, Ty) > 0) or (TileAt(Txr, Ty) > 0) then
          begin
             NextGroundYAt := Ty * TileHeight;
             Break;
          end;

          Ty := Ty + 1;
     end;
end;

procedure GameMap.Draw;
var
   Col, Row: Word;
   StartCol, StartRow: Word;
begin
     StartCol := X div TileWidth;
     StartRow := Y div TileHeight;

     for Row := 0 to NumCanvasRows - 1 do
         for Col := 0 to NumCanvasColumns - 1 do
             MapCanvas.Draw(
                 Col * TileWidth,
                 Row * TileHeight,
                 TileWidth,
                 TileHeight,
                 Tile[TileAt(StartCol + Col, StartRow + Row)]
             );

     BlitToScreen(X, Y);
end;

type
    PUpdateInfo = ^UpdateInfo;
    UpdateInfo = record
        Src, Dst, CopySize: Integer;
        StartTile: Integer;
        TileOffset: Integer;
        NumTiles: Integer;
        NeedsRedraw: Boolean;
    end;

function UpdateInfoFor(Prev, Next, ScreenSize, BufferSize, TileSize: Word): PUpdateInfo;
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
     NextScroll := Next mod TileSize;

     CopyOffset := Abs(NextStartTile - PrevStartTile) * TileSize;

     if Prev < Next then
     begin
         Result^.Src := CopyOffset - PrevScroll;
         Result^.Dst := 0;
         Result^.CopySize := ScreenSize - CopyOffset;
         Result^.TileOffset := Result^.CopySize div TileSize;
     end
     else
     begin
         Result^.Src := (TileSize - PrevScroll) mod TileSize;
         Result^.Dst := CopyOffset;

         if PrevScroll <> 0 then
         begin
             Inc(Result^.Dst, TileSize);
             Dec(Result^.CopySize, TileSize);
         end;

         Result^.TileOffset := 0;
         Result^.CopySize := ScreenSize - Result^.Dst + TileSize;
     end;

     Result^.StartTile := NextStartTile;
     Result^.NumTiles := (BufferSize - Result^.CopySize) div TileSize;
     Result^.NeedsRedraw := PrevStartTile <> NextStartTile;

     UpdateInfoFor := Result;
end;

procedure GameMap.Update;
var
   XInfo, YInfo: PUpdateInfo;
begin
     if (X = PrevX) and (Y = PrevY) then
        Exit;

     XInfo := UpdateInfoFor(PrevX, X, Screen^.CanvasWidth, MapCanvas.CanvasWidth, TileWidth);
     YInfo := UpdateInfoFor(PrevY, Y, Screen^.CanvasHeight, MapCanvas.CanvasHeight, TileHeight);

     if (XInfo^.NeedsRedraw) or (YInfo^.NeedsRedraw) then
     begin
         Screen^.CopyAreaTo(
             XInfo^.Src, YInfo^.Src,
             XInfo^.CopySize, XInfo^.CopySize,
             @MapCanvas,
             XInfo^.Dst, YInfo^.Dst
         );

         if XInfo^.NumTiles > 0 then
            DrawTiles(
                XInfo^.TileOffset,
                XInfo^.TileOffset + XInfo^.NumTiles - 1,
                0,
                NumCanvasRows - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );

         if YInfo^.NumTiles > 0 then
            DrawTiles(
                0,
                NumCanvasColumns - 1,
                YInfo^.TileOffset,
                YInfo^.TileOffset + YInfo^.NumTiles - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );
     end;

     BlitToScreen(X, Y);

     Dispose(XInfo);
     Dispose(YInfo);
end;

procedure GameMap.DrawTiles;
var
   Col, Row: Word;
begin
     for Row := StartRow to EndRow do
         for Col := StartCol to EndCol do
             MapCanvas.Draw(
                 Col * TileWidth,
                 Row * TileHeight,
                 TileWidth,
                 TileHeight,
                 Tile[TileAt(Col + ColOffset, Row + RowOffset)]
             );

end;

procedure GameMap.BlitToScreen;
begin
     MapCanvas.CopyAreaTo(
         X mod TileWidth, Y mod TileHeight,
         Screen^.CanvasWidth, Screen^.CanvasHeight,
         Screen,
         0, 0
     );


     PrevX := X;
     PrevY := Y;
end;

end.