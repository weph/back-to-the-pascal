program BackToThePascal;
uses Crt, Strings;

const
     Sprite: Array[0..63] of Byte = (
             0, 0, 0, 6, 6, 0, 0, 0,
             0, 0, 6, 6, 6, 6, 0, 0,
             0, 0, 6, 6, 6, 6, 6, 0,
             0, 0, 0, 6, 6, 0, 0, 0,
             0, 6, 6, 6, 6, 6, 6, 0,
             0, 6, 6, 0, 0, 6, 6, 0,
             6, 6, 6, 0, 0, 6, 6, 6,
             6, 6, 6, 0, 0, 6, 6, 6
     );

var
   x, y: Byte;
   i: Word;
   Running: Boolean;
   Tile: Array[0..1] of Array[0..63] of Byte;
   CurrentTile: Byte;
   Sx, Sy: Word;
   Buffer: Array[0..63999] of Byte;
   SpriteBackground: Array[0..63] of Byte;

procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

procedure PutPixel(X, Y: Word; Color: Byte);
begin
     Buffer[Y * 320 + X] := Color;
end;

procedure DrawSprite(X, Y: Word; Tile: Array of Byte);
var
   Tx, Ty, Color: Byte;
   Video: PChar;
   Row: PChar;
begin
     for Ty := 0 to 7 do
     begin
          Video := Ptr(Seg(Buffer), Ofs(Buffer) + (Y * 320 + X) + Ty * 320);
          Row := Ptr(Seg(SpriteBackground), Ofs(SpriteBackground) + Ty * 8);
          Move(Video^, Row^, 8);
     end;

     for Ty := 0 to 7 do
         for Tx := 0 to 7 do
         begin
             Color := Tile[Ty * 8 + Tx];
             if Color <> 0 then
                PutPixel(X + Tx, Y + Ty, Color);
         end;
end;

procedure DrawTile(X, Y: Word; Tile: Array of Byte);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     for Ty := 0 to 7 do
     begin
          Video := Ptr(Seg(Buffer), Ofs(Buffer) + (Y * 320 + X) + Ty * 320);
          Row := Ptr(Seg(Tile), Ofs(Tile) + Ty * 8);
          Move(Row^, Video^, 8);
     end;
end;

procedure UpdateScreen;
var
   Video: Array[0..63999] of Byte absolute $a000:$0000;
begin
     Move(Buffer, Video, 64000);
end;

procedure WaitForVRetrace;
begin
     asm
        mov dx, 03dah
        @wait_end:
        in al, dx
        test al, 8
        jnz @wait_end
        @wait_start:
        in al, dx
        test al, 8
        jz @wait_start
     end;
end;

procedure DrawMap;
var
   x, y: Byte;
begin
     for y := 0 to 24 do
         for x := 0 to 39 do
             DrawTile(x * 8, y * 8, Tile[CurrentTile]);
end;

begin
     SetVideoMode($13);

     for i := 0 to 63 do
     begin
         Tile[0][i] := 9;
         Tile[1][i] := 64 + i;
     end;

     for i := 0 to 63999 do
         Buffer[i] := 1;

     Sx := 10;
     Sy := 100;

     Running := true;

     CurrentTile := 0;

     DrawMap;

     while Running do
     begin
          DrawSprite(Sx - 1, Sy, SpriteBackground);

          DrawSprite(Sx, Sy, Sprite);

          Sx := Sx + 1;

          {CurrentTile := (CurrentTile + 1) mod 2;}

          WaitForVRetrace;

          UpdateScreen;

          if KeyPressed then
             Running := false;
     end;

     SetVideoMode(3);
end.