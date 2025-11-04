program PcxLoader;
uses Crt, PcxImg;

procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

var
   Image: ^PcxImage;
   X, Y: Word;
   Video: Array[0..63999] of Byte absolute $a000:$0000;

begin
     New(Image, Init('img\marty.pcx'));

     SetVideoMode($13);

     for Y := 0 to Image^.Height - 1 do
         for X := 0 to Image^.Width - 1 do
             Video[(Y + 100) * 320 + X + 160] := Ord(Image^.Data[Y * Image^.Width + X]);

     ReadLn;
     SetVideoMode(3);

     Dispose(Image, Destroy);
end.