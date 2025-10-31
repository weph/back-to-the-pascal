program BackToThePascal;
uses Crt, Strings;

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
     MapWidth = 80;
     MapHeight = 25;

     MartyImage1: SpriteData = (
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

     MartyImage2: SpriteData = (
             $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
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
             $00, $00, $00, $00, $00, $1c, $1c, $00, $00, $1c, $1c, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $1e, $1e, $00, $00, $1e, $1e, $00, $00, $00, $00, $00,
             $00, $00, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $00, $00
     );

     MartyImage3: SpriteData = (
             $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
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
             $00, $00, $00, $00, $00, $1c, $1c, $00, $00, $1c, $1c, $00, $00, $00, $00, $00,
             $00, $00, $00, $00, $00, $1e, $1e, $00, $00, $1e, $1e, $00, $00, $00, $00, $00,
             $00, $00, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $26, $00, $00
     );

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

     Map: Array[0..(MapWidth * MapHeight)-1] of Byte = (
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

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

1,2,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
     );

var
   i: Word;
   Running: Boolean;
   Tile: Array[0..2] of Array[0..63] of Byte;
   Buffer: ^VideoBuffer;
   MapBuffer: ^VideoBuffer;
   Marty: MartySprite;
   Key: Char;
   Sprites: SpriteCollection;
   MartyImages: SpriteImages;
   MapStartX: Byte;
   ScrollX: Word;
   MaxScrollX: Word;
   TC: Byte;

function NextGroundYAt(Sprite: PSprite): Word;
var
   Txl, Txr, Ty: Byte;
   X, Y: Word;
begin
     X := Sprite^.X;
     Y := Sprite^.Y;

     Txl := X div TileWidth;
     Txr := (X + Sprite^.Width) div TileWidth;
     Ty := Y div TileHeight;

     NextGroundYAt := ScreenHeight + Sprite^.Height * 2;

     while Ty < MapHeight do
     begin
          if (Map[Ty * MapWidth + Txl] > 0) or (Map[Ty * MapWidth + Txr] > 0) then
          begin
             NextGroundYAt := Ty * TileHeight;
             Break;
          end;

          Ty := Ty + 1;
     end;
end;

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
     GroundY := NextGroundYAt(@self) - Height - 2;

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
          if (Map[Ty * MapWidth + Txl] > 0) or (Map[Ty * MapWidth + Txr] > 0) then
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

procedure DrawTile(X, Y: Word; Tile: Array of Byte);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     if (X < ScreenWidth) and (Y < ScreenHeight) then
          CopyToBuffer(@Tile, X, Y, TileWidth, TileHeight);
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
     for y := 0 to MapHeight - 1 do
         for x := MapStartX to MapStartX + 39 do
             DrawTile((x - MapStartX) * TileWidth, y * TileHeight, Tile[Map[y * MapWidth + x]]);
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
              T := Map[Ty * MapWidth + Tx + MapOffsetX];
              {T := 2;}

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

     for Cy := 0 to MapHeight - 1 do
         for Cx := 0 to Columns - 1 do
             DrawTile(DrawPosition + Cx * TileWidth, Cy * TileHeight, Tile[Map[Cy * MapWidth + MapStartX + TileOffset + Cx]]);
end;


function EnemyInstance(X, Y: Word; PaletteOffset: Byte): PSprite;
var
   EnemyObj: ^Enemy;
begin
     New(EnemyObj);
     EnemyObj^.Init(X, Y, MartyImages, PaletteOffset);

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

     for i := 0 to 63 do
     begin
         Tile[0][i] := 9;
         Tile[1][i] := 8;
         Tile[2][i] := 0;
     end;

     for i := 0 to 63999 do
         Buffer^[i] := 0;

     Running := true;

     MapStartX := 0;
     MaxScrollX := (MapWidth + 2) * TileWidth - ScreenWidth;
     ScrollX := 0;
     TC := 1;
     DrawMap;

     MartyImages[0] := @MartyImage1;
     MartyImages[1] := @MartyImage2;
     MartyImages[2] := @MartyImage3;

     Marty.Init(10, 166, 16, 16, MartyImages);

     Sprites.Init;
     Sprites.Add(@Marty);
     Sprites.Add(EnemyInstance(300, 14, 2));
     Sprites.Add(EnemyInstance(10, 54, 4));

     for i := 0 to 14 do
         Sprites.Add(WaterInstance(136 + i * 8, 192));

     while Running do
     begin
          if Marty.X > ScreenWidth div 2
             then ScrollX := Marty.X - ScreenWidth div 2
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
                    'w': Marty.Ollie;
                    'a': Marty.Push(-1);
                    'd': Marty.Push(1);
                    't': TC := (TC + 1) mod 3;
               end;
          end;

          Sprites.Update;
     end;

     SetVideoMode(3);
end.