unit Debug;


interface

type
    FpsInfo = object
        private
            SampleSize: Word;
            Frames: Word;
            LastTs: LongInt;
        public
            CurrentFps: Real;
            constructor Init(TheSampleSize: Word);
            procedure Update;
            procedure Show;
    end;


implementation

uses Dos, Drivers;

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

procedure PutChar(X, Y: Word; C: Char);
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

               Vga[(Y + Cy) * 320 + X + Cx] := Color;

               Mask := Mask shr 1;
          end;
     end;
end;

procedure PutString(X, Y: Word; S: String);
var
   i: Integer;
begin
     for i := 1 to Length(S) do
         PutChar(X + (i - 1) * 8, Y, S[i]);
end;



constructor FpsInfo.Init;
begin
     SampleSize := TheSampleSize;
     Frames := 0;
     LastTs := Timestamp;
     CurrentFps := 0;
end;

procedure FpsInfo.Update;
var
   NextTs: LongInt;
begin
     Inc(Frames);

     if Frames < SampleSize then
        Exit;

     NextTs := Timestamp;

     CurrentFps := Frames / (NextTs - LastTs) * 100;
     LastTs := NextTs;
     Frames := 0;
end;

procedure FpsInfo.Show;
var
   S: String;
begin
     Str(CurrentFps:0:3, S);
     PutString(0, 0, S);
end;


end.