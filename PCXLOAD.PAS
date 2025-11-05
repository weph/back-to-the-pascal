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
   Sprite: PChar;

begin
     New(Image, Init('img\marty.pcx'));

     SetVideoMode($13);

     Sprite := Image^.SpriteAt(32, 0, 16, 16);

     for Y := 0 to 15 do
         for X := 0 to 15 do
             Video[(Y + 100) * 320 + X + 160] := Ord(Sprite[Y * 16 + X]);

     ReadLn;
     SetVideoMode(3);

     FreeMem(Sprite, SizeOf(Sprite));
     Dispose(Image, Destroy);
end.