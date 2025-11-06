program BackToThePascal;
uses Crt, Strings, PcxImg, Map;

const
     MaxSprites = 100;

type
    VideoBuffer = Array[0..63999] of Byte;
    SpriteData = Array[0..255] of Byte;
    SpriteImages = Array[0..2] of Pointer;

    Sprite = object
           constructor Init(
                       InitialX, InitialY: Word;
                       SpriteWidth, SpriteHeight: Byte;
                       TheImages: SpriteImages
           );

           public
                 X, Y: Word;
                 Width, Height: Byte;
                 procedure SetPosition(NewX, NewY: Word);
                 procedure Draw;
                 procedure Update; virtual;
           private
                  Images: SpriteImages;
                  CurrentImage: Byte;
                  Frames: Word;
                  Animating: Boolean;
    end;

    MartySprite = object(Sprite)
                private
                       Direction: ShortInt;
                       PushCycle: Byte;
                       OllieCycle: Byte;
                       OllieSpeed: Byte;
                       Speed: Byte;
                public
                      procedure Push(D: ShortInt);
                      procedure Ollie;
                      procedure Update; virtual;
    end;

    Enemy = object(Sprite)
                private
                       Direction: ShortInt;

                public
                      constructor Init(
                                  InitialX, InitialY: Word;
                                  TheImages: SpriteImages;
                                  PaletteOffset: Byte
                      );
                      procedure Update; virtual;
    end;

    AnimatedTile = object(Sprite)
                public
                      procedure Update; virtual;

    end;

    PSprite = ^Sprite;
    PMartySprite = ^MartySprite;

    SpriteCollection = object
            private
                   Sprites: Array[0..MaxSprites] of PSprite;
                   NumberOfSprites: Byte;
            public
                  constructor Init;
                  procedure Add(Sprite: PSprite);
                  procedure Draw;
                  procedure Update;
                  procedure Erase;
    end;


const
     ScreenWidth = 320;
     ScreenHeight = 200;
     TileWidth = 8;
     TileHeight = 8;

     Water1: Array[0..63] of Byte = (
             $37,$36,$35,$34,$33,$34,$35,$36,
             $36,$35,$34,$33,$34,$35,$36,$37,
             $35,$34,$33,$34,$35,$36,$37,$36,
             $34,$33,$34,$35,$36,$37,$36,$35,
             $33,$34,$35,$36,$37,$36,$35,$34,
             $34,$35,$36,$37,$36,$35,$34,$33,
             $35,$36,$37,$36,$35,$34,$33,$34,
             $36,$37,$36,$35,$34,$33,$34,$35
     );

     Water2: Array[0..63] of Byte = (
             $36,$35,$34,$33,$34,$35,$36,$37,
             $35,$34,$33,$34,$35,$36,$37,$36,
             $34,$33,$34,$35,$36,$37,$36,$35,
             $33,$34,$35,$36,$37,$36,$35,$34,
             $34,$35,$36,$37,$36,$35,$34,$33,
             $35,$36,$37,$36,$35,$34,$33,$34,
             $36,$37,$36,$35,$34,$33,$34,$35,
             $37,$36,$35,$34,$33,$34,$35,$36
     );

     Water3: Array[0..63] of Byte = (
             $35,$34,$33,$34,$35,$36,$37,$36,
             $34,$33,$34,$35,$36,$37,$36,$35,
             $33,$34,$35,$36,$37,$36,$35,$34,
             $34,$35,$36,$37,$36,$35,$34,$33,
             $35,$36,$37,$36,$35,$34,$33,$34,
             $36,$37,$36,$35,$34,$33,$34,$35,
             $37,$36,$35,$34,$33,$34,$35,$36,
             $36,$35,$34,$33,$34,$35,$36,$37
     );

var
   i: Word;
   Running: Boolean;
   Tile: Array[0..6] of PChar;
   Buffer: ^VideoBuffer;
   MapBuffer: ^VideoBuffer;
   Marty: ^MartySprite;
   Key: Char;
   Sprites: SpriteCollection;
   MapStartX: Byte;
   ScrollX: Word;
   MaxScrollX: Word;
   TilesImage: ^PcxImage;
   TheMap: ^GameMap;

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

constructor Sprite.Init(
            InitialX, InitialY: Word;
            SpriteWidth, SpriteHeight: Byte;
            TheImages: SpriteImages
);
begin
     X := InitialX;
     Y := InitialY;
     Width := SpriteWidth;
     Height := SpriteHeight;
     Images := TheImages;
     CurrentImage := 0;
     Animating := false;
end;

procedure Sprite.Draw;
var
   Tx, Ty, Color: Byte;
   Sx, Sy: Word;
   Row: PChar;
   Video: PChar;
begin
     for Ty := 0 to Height - 1 do
         for Tx := 0 to Width - 1 do
         begin
             Color := Byte(Ptr(Seg(Images[CurrentImage]^), Ofs(Images[CurrentImage]^) + Ty * Width + Tx)^);
             Sx := X + Tx - MapStartX * TileWidth;
             Sy := Y + Ty;
             if (Color <> 0) and (Sx >= 0) and (Sx < ScreenWidth) and (Sy >= 0) and (Sy < ScreenHeight) then
                PutPixel(Sx, Sy, Color);
         end;
end;

procedure Sprite.SetPosition(NewX, NewY: Word);
begin
     X := NewX;
     Y := NewY;
end;

procedure Sprite.Update;
begin
     if Animating then
     begin
          Inc(Frames);

          if Frames mod 3 = 0 then
               CurrentImage := (CurrentImage + 1) mod 3;

          if Frames > 9 then
             Animating := false;
     end;
end;

procedure MartySprite.Push(D: ShortInt);
begin
     Direction := D;
     PushCycle := 30;
     Speed := 4;
     Animating := true;
     Frames := 0;
     CurrentImage := 0;
end;

procedure MartySprite.Ollie;
begin
     if OllieCycle = 0 then
     begin
        OllieCycle := 7;
        OllieSpeed := 5;
        Speed := 6;
     end;
end;

procedure MartySprite.Update;
var
   GroundY, NextX, NextY: Word;
   Txl, Txr, Tyt, Tyb, Ty: Byte;
   Collision: Boolean;
begin
     Sprite.Update;

     NextX := X;
     NextY := Y;
     GroundY := TheMap^.NextGroundYAt(X, X + Width, Y) - Height - 2;

     if OllieCycle > 0 then
     begin
          NextY := Y - OllieSpeed;
          OllieCycle := OllieCycle - 1;
          if OllieSpeed > 1 then
             OllieSpeed := OllieSpeed - 1;

          Speed := 4;
     end
     else if Y < GroundY then
     begin
          NextY := Y + 2;
          {Y := Y + OllieSpeed;
          Speed := 3;}
     end;

     if PushCycle > 0 then
     begin
          NextX := X + Speed * Direction;

          if Speed > 1 then
             Speed := Speed - 1;

          PushCycle := PushCycle - 1;
     end;

     Txl := NextX div TileWidth;
     Txr := (NextX + Width) div TileWidth;
     Tyt := NextY div TileHeight;
     Tyb := (NextY + Height) div TileHeight;

     Collision := false;
     for Ty := Tyt to Tyb do
          if (TheMap^.TileAt(Txl, Ty) > 0) or (TheMap^.TileAt(Txr, Ty) > 0) then
          begin
               Collision := true;
               Break;
          end;

     if not Collision then
     begin
          X := NextX;
     end
     else
     begin
          OllieCycle := 0;
     end;

     if NextY > GroundY then
        NextY := GroundY;

     Y := NextY;
end;

constructor Enemy.Init(
            InitialX, InitialY: Word;
            TheImages: SpriteImages;
            PaletteOffset: Byte
);
begin
     Sprite.Init(InitialX, InitialY, 16, 16, TheImages);
     Direction := -1;
end;

procedure Enemy.Update;
begin
     Animating := true;

     Sprite.Update;

     X := X + Direction;

     if (X <= 0) or ((X + Width) > ScreenWidth) then
        Direction := Direction * -1;
end;

procedure AnimatedTile.Update;
begin
     Animating := true;

     Sprite.Update;
end;

procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

procedure DrawTile(X, Y: Word; Tile: PChar);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     if (X < ScreenWidth) and (Y < ScreenHeight) then
          CopyToBuffer(Tile, X, Y, TileWidth, TileHeight);
end;

procedure UpdateScreen;
var
   Y: Byte;
   Video: Array[0..63999] of Byte absolute $a000:$0000;
   Source, Dest: Pointer;
   XOffset: Word;
begin
     XOffset := ScrollX mod TileWidth;

     for Y := 0 to ScreenHeight - 1 do
     begin
          Source := Ptr(Seg(Buffer^), Ofs(Buffer^) + Y * ScreenWidth + XOffset);
          Dest := Ptr(Seg(Video), Ofs(Video) + Y * ScreenWidth + TileWidth);
          Move(Source^, Dest^, 304);
     end;
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
     for y := 0 to TheMap^.Height - 1 do
         for x := MapStartX to MapStartX + 39 do
             DrawTile((x - MapStartX) * TileWidth, y * TileHeight, Tile[TheMap^.TileAt(x, Y)]);
end;

procedure RedrawMapParts(S: PSprite);
var
   Tx, Ty, MapOffsetX, T: Byte;
   TxStart, TxEnd: Byte;
   TyStart, TyEnd: Byte;
begin
     MapOffsetX := ScrollX div TileWidth;

     TxStart := (S^.X - ScrollX) div TileWidth;
     TxEnd := (S^.X + S^.Width - ScrollX) div TileWidth + 1;

     TyStart := S^.Y div TileHeight;
     TyEnd := (S^.Y + S^.Height) div TileHeight + 1;

     for Ty := TyStart to TyEnd do
         for Tx := TxStart to TxEnd do
         begin
              T := TheMap^.TileAt(Tx + MapOffsetX, Ty);

              DrawTile(Tx * TileWidth, Ty * TileHeight, Tile[T]);
         end;
end;

procedure UpdateMap;
var
   Cx, Cy: Byte;
   Source, Dest: Pointer;
   NextMapStartX, TileOffset, Columns: Byte;
   CopyWidth, SourceOffset, DestOffset, DrawPosition: Word;
begin
     NextMapStartX := ScrollX div TileWidth;

     if MapStartX = NextMapStartX then exit;

     Columns := Abs(NextMapStartX - MapStartX);

     if NextMapStartX > MapStartX then
     begin
          SourceOffset := Columns * TileWidth;
          DestOffset := 0;
          TileOffset := 40 - Columns;
          DrawPosition := TileOffset * TileWidth;
     end
     else
     begin
          SourceOffset := 0;
          DestOffset := Columns * TileWidth;
          TileOffset := 0;
          DrawPosition := 0;
     end;

     MapStartX := NextMapStartX;

     CopyWidth := ScreenWidth - Columns * TileWidth;

     for Cy := 0 to ScreenHeight - 1 do
     begin
          Source := Ptr(Seg(Buffer^), Ofs(Buffer^) + Cy * ScreenWidth + SourceOffset);
          Dest := Ptr(Seg(MapBuffer^), Ofs(MapBuffer^) + Cy * ScreenWidth + DestOffset);
          Move(Source^, Dest^, CopyWidth);
     end;

     Move(MapBuffer^, Buffer^, 64000);

     for Cy := 0 to TheMap^.Height - 1 do
         for Cx := 0 to Columns - 1 do
             DrawTile(DrawPosition + Cx * TileWidth, Cy * TileHeight, Tile[TheMap^.TileAt(MapStartX + TileOffset + Cx, Cy)]);
end;

function MartyInstance(X, Y: Word): PMartySprite;
var
   Marty: ^MartySprite;
   SpriteSheet: ^PcxImage;
   Images: SpriteImages;
begin
     New(SpriteSheet, Init('img\marty.pcx'));

     Images[0] := SpriteSheet^.SpriteAt(0, 0, 16, 16);
     Images[1] := SpriteSheet^.SpriteAt(16, 0, 16, 16);
     Images[2] := SpriteSheet^.SpriteAt(32, 0, 16, 16);

     Dispose(SpriteSheet, Destroy);

     New(Marty, Init(X, Y, 16, 16, Images));

     MartyInstance := Marty;
end;

function EnemyInstance(X, Y: Word; PaletteOffset: Byte): PSprite;
var
   EnemyObj: ^Enemy;
   SpriteSheet: ^PcxImage;
   Images: SpriteImages;

begin
     New(SpriteSheet, Init('img\marty.pcx'));

     Images[0] := SpriteSheet^.SpriteAt(0, 0, 16, 16);
     Images[1] := SpriteSheet^.SpriteAt(16, 0, 16, 16);
     Images[2] := SpriteSheet^.SpriteAt(32, 0, 16, 16);

     Dispose(SpriteSheet, Destroy);

     New(EnemyObj, Init(X, Y, Images, PaletteOffset));

     EnemyInstance := EnemyObj;
end;

function WaterInstance(X, Y: Word): PSprite;
var
   Water: ^AnimatedTile;
   WaterImages: SpriteImages;
begin
     WaterImages[0] := @Water1;
     WaterImages[1] := @Water2;
     WaterImages[2] := @Water3;

     New(Water);
     Water^.Init(X, Y, 8, 8, WaterImages);

     WaterInstance := Water;
end;

constructor SpriteCollection.Init;
begin
     NumberOfSprites := 0;
end;

procedure SpriteCollection.Add(Sprite: PSprite);
begin
     Sprites[NumberOfSprites] := Sprite;
     Inc(NumberOfSprites);
end;

procedure SpriteCollection.Draw;
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
                   Sprites[i]^.Draw;
end;

procedure SpriteCollection.Update;
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
              Sprites[i]^.Update;
end;

procedure SpriteCollection.Erase;
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
              RedrawMapParts(Sprites[i]);
end;

begin
     New(Buffer);
     New(MapBuffer);

     SetVideoMode($13);

     New(TheMap, Init('map.txt'));

     New(TilesImage, Init('img\tiles.pcx'));
     Tile[0] := TilesImage^.SpriteAt(0, 0, TileWidth, TileHeight);
     Tile[1] := TilesImage^.SpriteAt(0, 8, TileWidth, TileHeight);
     Tile[2] := TilesImage^.SpriteAt(8, 8, TileWidth, TileHeight);
     Tile[3] := TilesImage^.SpriteAt(16, 8, TileWidth, TileHeight);
     Tile[4] := TilesImage^.SpriteAt(24, 8, TileWidth, TileHeight);
     Tile[5] := TilesImage^.SpriteAt(32, 8, TileWidth, TileHeight);
     Tile[6] := TilesImage^.SpriteAt(40, 8, TileWidth, TileHeight);

     for i := 0 to 63999 do
         Buffer^[i] := 0;

     Running := true;

     MapStartX := 0;
     MaxScrollX := (TheMap^.Width + 2) * TileWidth - ScreenWidth;
     ScrollX := 0;
     DrawMap;

     Marty := MartyInstance(10, 166);

     Sprites.Init;
     Sprites.Add(Marty);
     Sprites.Add(EnemyInstance(300, 14, 2));
     Sprites.Add(EnemyInstance(10, 54, 4));

     for i := 0 to 14 do
         Sprites.Add(WaterInstance(136 + i * 8, 192));

     while Running do
     begin
          if Marty^.X > ScreenWidth div 2
             then ScrollX := Marty^.X - ScreenWidth div 2
             else ScrollX := 0;

          if ScrollX > MaxScrollX then ScrollX := MaxScrollX;

          UpdateMap;

          Sprites.Draw;

          WaitForVRetrace;

          UpdateScreen;

          Sprites.Erase;

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'w': Marty^.Ollie;
                    'a': Marty^.Push(-1);
                    'd': Marty^.Push(1);
               end;
          end;

          Sprites.Update;
     end;

     SetVideoMode(3);
end.