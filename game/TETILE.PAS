unit TETile;


interface

type
    PTTile = ^TTile;
    TTile = object
          Width, Height: Word;
          MemSize: Word;
          Size: Word;
          Data: PChar;

          constructor From(Pixels: PChar; ImageWidth, ImageHeight: Word);
          destructor Destroy;
    end;


implementation

constructor TTile.From;
var
   Result: PChar;
   i, Pos, CurrentLength: Word;
   X, Y, PrevY: Word;
begin
     Width := ImageWidth;
     Height := ImageHeight;
     MemSize := Width * Height * 2 + Height * 2;
     GetMem(Data, MemSize);

     Pos := 0;
     CurrentLength := 0;
     X := 0;
     Y := 0;
     PrevY := 0;

     for i := 0 to Width * Height - 1 do
     begin
          X := i mod Width;
          Y := i div Width;

          if Ord(Pixels[i]) = 0 then
          begin
             if CurrentLength > 0 then
                Inc(Pos, CurrentLength + 3);

             CurrentLength := 0;
             continue;
          end;

          if (Y <> PrevY) and (CurrentLength > 0) then
          begin
               Inc(Pos, CurrentLength + 3);
               CurrentLength := 0;
          end;

          if CurrentLength = 0 then
          begin
               Data[Pos] := Chr(X);
               Data[Pos + 1] := Chr(Y);
               Data[Pos + 2] := Chr(0);
          end;

          Inc(CurrentLength);

          Data[Pos + 2] := Chr(CurrentLength);
          Data[Pos + 2 + CurrentLength] := Pixels[i];

          PrevY := Y;
     end;

     Size := Pos + CurrentLength;
end;

destructor TTile.Destroy;
begin
     FreeMem(Data, MemSize);
end;

end.