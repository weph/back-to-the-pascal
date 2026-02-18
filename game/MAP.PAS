unit Map;

interface

uses Screen, PcxImg, VGA;

const
    MaxWidth = 200;
    MaxHeight = 100;

type
    PTileInfo = ^TTileInfo;
    TTileInfo = record
        Solid: Boolean;
        YOffset: Byte;
    end;

    PGameMap = ^GameMap;
    GameMap = object
            private
                WidthInColumns, HeightInRows: Word;
                Data: Array[0..MaxWidth * MaxHeight] of Byte;

                procedure BlitToScreen(X, Y: Word);
            public
                Width, Height: Word;
                TileWidth, TileHeight: Word;
                PrevX, PrevY: Word;
                MapCanvas: Buffer;

                constructor Init(Filename: String);
                function TileAt(X, Y: Word): Byte;
                procedure GetTileInfo(X, Y: Word; var Info: TTileInfo);
                function NextGroundYAt(XLeft, XRight, Y: Word): Word;
                procedure Update(X, Y: Word);
    end;


implementation

uses Crt;

constructor GameMap.Init;
var
   MapFile: Text;
   Line: String;
   X, Y: Word;
begin
     Assign(MapFile, Filename);
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
end;

function GameMap.TileAt(X, Y: Word): Byte;
var
   Index: Word;
begin
     Index := Y * WidthInColumns + X;

     if Index > MaxWidth * MaxHeight then
     begin
        TileAt := 255;
        Exit;
     end;


     TileAt := Data[Y * WidthInColumns + X]
end;

procedure GameMap.GetTileInfo;
var
   T: Byte;
begin
     T := Data[Y * WidthInColumns + X];

     case Chr(T + Ord('0')) of
          'z', '{', '|': begin
               Info.Solid := true;
               Info.YOffset := 8;
          end;
          'l',
          'c', 'd', 'e',
          'q', 'r', 's': begin
               Info.Solid := true;
               Info.YOffset := 0;
          end;
          'v', 'w', 'x': begin
               Info.Solid := true;
               Info.YOffset := 0;
          end;
     else
         Info.Solid := false
     end;
end;

function GameMap.NextGroundYAt(XLeft, XRight, Y: Word): Word;
var
   Txl, Txr, Ty: Byte;
   InfoL, InfoR: TTileInfo;
begin
     Txl := XLeft div TileWidth;
     Txr := XRight div TileWidth;
     Ty := Y div TileHeight;

     NextGroundYAt := HeightInRows * TileHeight + 32;

     while Ty < HeightInRows do
     begin
          GetTileInfo(Txl, Ty, InfoL);
          GetTileInfo(Txr, Ty, InfoR);

          if (InfoL.Solid) or (InfoR.Solid) then
          begin
             NextGroundYAt := Ty * TileHeight + InfoL.YOffset;
             Break;
          end;

          Ty := Ty + 1;
     end;
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
     Dec(Result^.CopySize, Result^.CopySize mod TileSize);

     if (Result^.Dst + Result^.CopySize > BufferSize) then
        Result^.CopySize := BufferSize - Result^.Dst;

     Result^.StartTile := NextStartTile;
     Result^.NumTilesStart := Result^.Dst div TileSize;
     Result^.NumTilesEnd := (BufferSize - Result^.Dst - Result^.CopySize) div TileSize;
     Result^.NeedsRedraw := PrevStartTile <> NextStartTile;

     UpdateInfoFor := Result;
end;

procedure GameMap.Update;
var
   XInfo, YInfo: PUpdateInfo;
   XColumns: LongInt;
begin
     {if (X = PrevX) and (Y = PrevY) then
        Exit;

     XInfo := UpdateInfoFor(PrevX, X, Screen^.CanvasWidth, MapCanvas.CanvasWidth, TileWidth);
     YInfo := UpdateInfoFor(PrevY, Y, Screen^.CanvasHeight, MapCanvas.CanvasHeight, TileHeight);

     if (XInfo^.NeedsRedraw) or (YInfo^.NeedsRedraw) then
     begin
         Screen^.CopyAreaTo(
             XInfo^.Src, YInfo^.Src,
             XInfo^.CopySize, YInfo^.CopySize,
             @MapCanvas,
             XInfo^.Dst, YInfo^.Dst
         );

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
                NumCanvasColumns - 1,
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
                NumCanvasRows - YInfo^.NumTilesEnd,
                NumCanvasRows - 1,
                XInfo^.StartTile,
                YInfo^.StartTile
            );
     end;

     BlitToScreen(X, Y);

     Dispose(XInfo);
     Dispose(YInfo);}
end;

procedure GameMap.BlitToScreen;
begin
     {MapCanvas.CopyAreaTo(
         X mod TileWidth, Y mod TileHeight,
         Screen^.CanvasWidth, Screen^.CanvasHeight,
         Screen,
         0, 0
     );


     PrevX := X;
     PrevY := Y;}
end;

end.