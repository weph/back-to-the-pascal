program BackToThePascal;
uses Crt, Strings;

type
    VideoBuffer = Array[0..63999] of Byte;
    SpriteData = Array[0..255] of Byte;

    Sprite = object
           constructor Init(TheImage: SpriteData);

           public
                 procedure SetPosition(NewX, NewY: Word);
                 procedure Draw;
                 procedure Erase;

           private
                  X, Y, PrevX, PrevY: Word;
                  Image: SpriteData;
                  Background: SpriteData;
    end;

const
     ScreenWidth = 320;
     ScreenHeight = 200;

     MartyImage: SpriteData = (
             $00, $00, $00, $00, $00, $72, $72, $72, $72, $72, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $72, $72, $72, $72, $72, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $72, $72, $59, $1f, $59, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $72, $59, $59, $59, $59, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $00, $59, $59, $59, $00, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $15, $04, $04, $28, $28, $04, $04, $15, $00, $00, $00, $00,
             $00, $00, $00, $15, $15, $04, $15, $28, $28, $15, $04, $15, $15, $00, $00, $00,
             $00, $59, $59, $15, $15, $04, $04, $28, $28, $04, $04, $15, $15, $59, $59, $00,
             $00, $00, $00, $00, $00, $04, $04, $28, $28, $04, $04, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $15, $15, $28, $28, $15, $15, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $09, $09, $09, $09, $09, $09, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $09, $09, $00, $00, $09, $09, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $09, $09, $00, $00, $09, $09, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $1c, $1c, $00, $00, $1c, $1c, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $1e, $1e, $00, $00, $1e, $1e, $00, $00, $00, $00, $00,
             $00, $00, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $00, $00
     );

var
   i: Word;
   Running: Boolean;
   Tile: Array[0..1] of Array[0..63] of Byte;
   CurrentTile: Byte;
   Sx, Sy: Word;
   Buffer: ^VideoBuffer;
   Marty: Sprite;
   MartySpeed: Byte;
   Key: Char;

procedure PutPixel(X, Y: Word; Color: Byte);
begin
     Buffer^[Y * ScreenWidth + X] := Color;
end;

procedure CopyFromBuffer(Dest: Pointer; X, Y, Width, Height: Word);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
   SrcSeg, SrcOfs, DstSeg, DstOfs: Word;
begin
     SrcSeg := Seg(Buffer^);
     SrcOfs := Ofs(Buffer^) + (Y * ScreenWidth + X);

     DstSeg := Seg(Dest^);
     DstOfs := Ofs(Dest^);

     for Ty := 0 to Height - 1 do
     begin
          Video := Ptr(SrcSeg, SrcOfs + Ty * ScreenWidth);
          Row := Ptr(DstSeg, DstOfs + Ty * Width);
          Move(Video^, Row^, Width);
     end;
end;

procedure CopyToBuffer(Source: Pointer; X, Y, Width, Height: Word);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
   SrcSeg, SrcOfs, DstSeg, DstOfs: Word;
begin
     SrcSeg := Seg(Source^);
     SrcOfs := Ofs(Source^);

     DstSeg := Seg(Buffer^);
     DstOfs := Ofs(Buffer^) + (Y * ScreenWidth + X);

     for Ty := 0 to Height - 1 do
     begin
          Video := Ptr(SrcSeg, SrcOfs + Ty * Width);
          Row := Ptr(DstSeg, DstOfs + Ty * ScreenWidth);
          Move(Video^, Row^, Width);
     end;
end;

constructor Sprite.Init(TheImage: SpriteData);
begin
     Image := TheImage;
     X := 160;
     y := 100;
end;

procedure Sprite.Draw;
var
   Tx, Ty, Color: Byte;
   Row: PChar;
   Video: PChar;
begin
     PrevX := X;
     PrevY := Y;

     CopyFromBuffer(@Background, X, Y, 16, 16);

     for Ty := 0 to 15 do
         for Tx := 0 to 15 do
         begin
             Color := Image[Ty * 16 + Tx];
             if Color <> 0 then
                PutPixel(X + Tx, Y + Ty, Color);
         end;
end;

procedure Sprite.Erase;
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     CopyToBuffer(@Background, PrevX, PrevY, 16, 16);
end;

procedure Sprite.SetPosition(NewX, NewY: Word);
begin
     X := NewX;
     Y := NewY;
end;

procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

procedure DrawTile(X, Y: Word; Tile: Array of Byte);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     CopyToBuffer(@Tile, X, Y, 8, 8);
end;

procedure UpdateScreen;
var
   Video: Array[0..63999] of Byte absolute $a000:$0000;
begin
     Move(Buffer^, Video, 64000);
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
     New(Buffer);
     SetVideoMode($13);

     for i := 0 to 63 do
     begin
         Tile[0][i] := 9;
         Tile[1][i] := 64 + i;
     end;

     for i := 0 to 63999 do
         Buffer^[i] := 1;

     Sx := 10;
     Sy := 100;

     Running := true;

     CurrentTile := 0;

     DrawMap;

     Marty.Init(MartyImage);
     MartySpeed := 8;
     while Running do
     begin
          Marty.SetPosition(Sx, Sy);
          Marty.Draw;

          WaitForVRetrace;

          UpdateScreen;

          Marty.Erase;

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'a': Sx := Sx - MartySpeed;
                    'd': Sx := Sx + MartySpeed;
               end;
          end;
     end;

     SetVideoMode(3);
end.