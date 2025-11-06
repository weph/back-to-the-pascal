unit Map;

interface

const
    MaxWidth = 200;
    MaxHeight = 25;
    TileWidth = 8;
    TileHeight = 8;

type
    GameMap = object
            private
                   Data: Array[0..MaxWidth * MaxHeight] of Byte;
            public
                  Width, Height: Word;

                  constructor Init(Filename: String);
                  function TileAt(X, Y: Word): Byte;
                  function NextGroundYAt(XLeft, XRight, Y: Word): Word;
    end;

implementation

constructor GameMap.Init(Filename: String);
var
   MapFile: Text;
   Line: String;
   X, Y: Word;
begin
     Assign(MapFile, 'map.txt');
     Reset(MapFile);

     Y := 0;

     while not Eof(MapFile) do
     begin
          ReadLn(MapFile, Line);

          if Y = 0 then
             Width := Length(Line);

          for X := 1 to Length(Line) do
              Data[Y * Width + X - 1] := Ord(Line[X]) - Ord('0');

          Inc(Y);
     End;

     Height := Y;

     Close(MapFile);
end;

function GameMap.TileAt(X, Y: Word): Byte;
begin
     TileAt := Data[Y * Width + X]
end;

function GameMap.NextGroundYAt(XLeft, XRight, Y: Word): Word;
var
   Txl, Txr, Ty: Byte;
begin
     Txl := XLeft div TileWidth;
     Txr := XRight div TileWidth;
     Ty := Y div TileHeight;

     NextGroundYAt := Height * TileHeight + 32;

     while Ty < Height do
     begin
          if (TileAt(Txl, Ty) > 0) or (TileAt(Txr, Ty) > 0) then
          begin
             NextGroundYAt := Ty * TileHeight;
             Break;
          end;

          Ty := Ty + 1;
     end;
end;

begin
end.