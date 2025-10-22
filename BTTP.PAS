program BackToThePascal;
uses Crt, Strings;

type
    VideoBuffer = Array[0..63999] of Byte;
    SpriteData = Array[0..255] of Byte;

    Sprite = object
           constructor Init(InitialX, InitialY: Word; TheImage: SpriteData);

           public
                 X, Y: Word;
                 procedure SetPosition(NewX, NewY: Word);
                 procedure Draw;
                 procedure Erase;
                 procedure Update; virtual;
           private
                  PrevX, PrevY: Word;
                  Image: SpriteData;
                  Background: SpriteData;
    end;

    MartySprite = object(Sprite)
                private
                       Direction: ShortInt;
                       PushCycle: Byte;
                       OllieCycle: Byte;
                       OllieSpeed: Byte;
                       Speed: Byte;
                       GroundY: Word;
                public
                      procedure Push(D: ShortInt);
                      procedure Ollie;
                      procedure Update; virtual;
    end;

    Enemy = object(Sprite)
                private
                       Direction: ShortInt;

                public
                      constructor Init(InitialX, InitialY: Word; TheImage: SpriteData);
                      procedure Update; virtual;
    end;

    PSprite = ^Sprite;

const
     ScreenWidth = 320;
     ScreenHeight = 200;
     SpriteWidth = 16;
     SpriteHeight = 16;

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

     Map: Array[0..(25 * 40)-1] of Byte = (
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
     );

var
   i: Word;
   Running: Boolean;
   Tile: Array[0..2] of Array[0..63] of Byte;
   CurrentTile: Byte;
   Buffer: ^VideoBuffer;
   Marty: MartySprite;
   Key: Char;
   Sprites: Array[0..2] of PSprite;

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

constructor Sprite.Init(InitialX, InitialY: Word; TheImage: SpriteData);
begin
     X := InitialX;
     Y := InitialY;
     Image := TheImage;
end;

procedure Sprite.Draw;
var
   Tx, Ty, Color: Byte;
   Row: PChar;
   Video: PChar;
begin
     PrevX := X;
     PrevY := Y;

     CopyFromBuffer(@Background, X, Y, SpriteWidth, SpriteHeight);

     for Ty := 0 to SpriteHeight - 1 do
         for Tx := 0 to SpriteWidth - 1 do
         begin
             Color := Image[Ty * SpriteWidth + Tx];
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
     CopyToBuffer(@Background, PrevX, PrevY, SpriteWidth, SpriteHeight);
end;

procedure Sprite.SetPosition(NewX, NewY: Word);
begin
     X := NewX;
     Y := NewY;
end;

procedure Sprite.Update;
begin
end;

procedure MartySprite.Push(D: ShortInt);
begin
     Direction := D;
     PushCycle := 30;
     Speed := 4;
end;

procedure MartySprite.Ollie;
begin
     if OllieCycle = 0 then
     begin
        OllieCycle := 6;
        OllieSpeed := 4;
        GroundY := Y;
     end;
end;

procedure MartySprite.Update;
begin
     if PushCycle > 0 then
     begin
          X := X + Speed * Direction;

          if Speed > 1 then
             Speed := Speed - 1;

          PushCycle := PushCycle - 1;
     end;

     if OllieCycle > 0 then
     begin
          Y := Y - OllieSpeed;
          OllieCycle := OllieCycle - 1;
          if OllieSpeed > 1 then
             OllieSpeed := OllieSpeed - 1;
     end
     else if Y < GroundY then
     begin
          Y := Y + OllieSpeed;
     end;

     if (X <= 0) or ((X + SpriteWidth) > ScreenWidth) then
     begin
          PushCycle := 0;
     end;
end;

constructor Enemy.Init(InitialX, InitialY: Word; TheImage: SpriteData);
begin
     Sprite.Init(InitialX, InitialY, TheImage);
     Direction := -1;
end;

procedure Enemy.Update;
begin
     X := X + Direction;

     if (X <= 0) or ((X + SpriteWidth) > ScreenWidth) then
        Direction := Direction * -1;
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
             DrawTile(x * 8, y * 8, Tile[Map[y * 40 + x]]);
end;

procedure RedrawMapParts(S: PSprite);
var
   X, Y, StartX, StartY, EndX, EndY: Byte;
begin
     StartX := S^.X div 8;
     StartY := S^.Y div 8;
     EndX := StartX + 2;
     EndY := StartY + 2;

     if EndX > 39 then
        EndX := 39;

     if EndY > 24 then
        EndY := 24;

     for Y := StartY to EndY do
         for X := StartX to EndX do
             DrawTile(X * 8, Y * 8, Tile[Map[Y * 40 + X]]);
end;

function EnemyInstance(X, Y: Word): PSprite;
var
   EnemyObj: ^Enemy;
begin
     New(EnemyObj);
     EnemyObj^.Init(X, Y, MartyImage);

     EnemyInstance := EnemyObj;
end;

begin
     New(Buffer);
     SetVideoMode($13);

     for i := 0 to 63 do
     begin
         Tile[0][i] := 9;
         Tile[1][i] := 8;
         Tile[2][i] := 0;
     end;

     for i := 0 to 63999 do
         Buffer^[i] := 0;

     Running := true;

     CurrentTile := 0;

     DrawMap;

     Marty.Init(100, 166, MartyImage);

     Sprites[0] := @Marty;
     Sprites[1] := EnemyInstance(300, 166);
     Sprites[2] := EnemyInstance(10, 166);

     while Running do
     begin
          for i := 0 to 2 do
              Sprites[i]^.Draw;

          WaitForVRetrace;

          UpdateScreen;

          for i := 0 to 2 do
              RedrawMapParts(Sprites[i]);

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'w': Marty.Ollie;
                    'a': Marty.Push(-1);
                    'd': Marty.Push(1);
               end;
          end;

          for i := 0 to 2 do
              Sprites[i]^.Update;
     end;

     SetVideoMode(3);
end.