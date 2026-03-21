unit IsoMap;

interface

const
    MaxWidth = 100;
    MaxHeight = 100;
    MaxDepth = 4;

type
    PGameMap = ^TIsoMap;
    TIsoMap = object
        Depth, Width, Height: Word;
        Data: Array[0..MaxDepth - 1,0..MaxHeight - 1,0..MaxWidth - 1] of Byte;

        constructor Init(Filename: String);
        function TileAt(X, Y, Z: Word): Byte;
        function IsWalkable(X, Y: Word): Boolean;
    end;


implementation

constructor TIsoMap.Init;
var
   MapFile: Text;
   Line: String;
   X, Y, Z: Word;
   LL: Word;
begin
     Assign(MapFile, Filename);
     Reset(MapFile);

     Y := 0;
     Z := 0;

     while not Eof(MapFile) do
     begin
          ReadLn(MapFile, Line);

          if Length(Line) = 0 then begin
             Inc(Z);
             Y := 0;
             continue;
          end;

          if (Z = 0) and (Y = 0) then begin
             Width := Length(Line);
          end;

          for X := 1 to Length(Line) do begin
              Data[Z][Y][X - 1] := Ord(Line[X]) - Ord('0');
          end;

          Inc(Y);
     End;

     Height := Y;
     Depth := Z;

     Close(MapFile);
end;

function TIsoMap.TileAt;
var
   Index: Word;
begin
     if (X > MaxWidth) or (Y > MaxHeight) or (Z > MaxDepth) then begin
        TileAt := 0;
        Exit;
     end;


     TileAt := Data[Z][Y][X]
end;

function TIsoMap.IsWalkable(X, Y: Word): Boolean;
begin
     IsWalkable := true;
end;

end.