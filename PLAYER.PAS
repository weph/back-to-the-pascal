unit Player;


interface

uses Sprite, Map, PcxImg, Screen;

type
    PMartySprite = ^MartySprite;
    MartySprite = object(BaseSprite)
                private
                       Direction: ShortInt;
                       PushCycle: Byte;
                       OllieCycle: Byte;
                       OllieSpeed: Byte;
                       Speed: Byte;
                public
                      constructor Init(
                          TheScreen: PCanvas;
                          InitialX, InitialY: Word;
                          SpriteWidth, SpriteHeight: Byte;
                          TheImages: SpriteImages;
                          TheImagesLength: Byte
                      );

                      procedure Push(D: ShortInt);
                      procedure Ollie;
                      procedure Update(TheMap: PGameMap); virtual;
    end;

function MartyInstance(TheScreen: PCanvas; X, Y: Word): PMartySprite;


implementation

function MartyInstance;
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

     New(Marty, Init(TheScreen, X, Y, 16, 16, Images, 3));

     MartyInstance := Marty;
end;


constructor MartySprite.Init;
begin
     inherited Init(TheScreen, InitialX, InitialY, SpriteWidth, SpriteHeight, TheImages, TheImagesLength);

     Direction := 1;
     PushCycle := 0;
     OllieCycle := 0;
     OllieSpeed := 0;
     Speed := 0;
end;

procedure MartySprite.Push(D: ShortInt);
begin
     Direction := D;
     PushCycle := 30;
     Speed := 6;
     Animating := true;
     Frames := 0;
     CurrentImage := 0;
end;

procedure MartySprite.Ollie;
begin
     if OllieCycle = 0 then
     begin
        OllieCycle := 7;
        OllieSpeed := 8;
        Speed := 6;
     end;
end;

procedure MartySprite.Update(TheMap: PGameMap);
var
   GroundY, NextX, NextY: Word;
   Txl, Txr, Tyt, Tyb, Ty: Byte;
   Collision: Boolean;
begin
     BaseSprite.Update(TheMap);

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
          NextY := Y + 4;
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

     Txl := NextX div TheMap^.TileWidth;
     Txr := (NextX + Width) div TheMap^.TileWidth;
     Tyt := NextY div TheMap^.TileHeight;
     Tyb := (NextY + Height) div TheMap^.TileHeight;

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


begin
end.