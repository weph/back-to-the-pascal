unit Enemy;


interface

uses Sprite, Map, PcxImg, Screen;

type
    EnemySprite = object(BaseSprite)
                private
                       Direction: ShortInt;

                public
                      constructor Init(
                                  TheScreen: PCanvas;
                                  InitialX, InitialY: Word;
                                  TheImages: SpriteImages;
                                  TheImagesLength: Byte;
                                  PaletteOffset: Byte
                      );
                      procedure Update(TheMap: PGameMap); virtual;
    end;

function EnemyInstance(TheScreen: PCanvas; X, Y: Word; PaletteOffset: Byte): PSprite;


implementation

function EnemyInstance;
var
   EnemyObj: ^EnemySprite;
   SpriteSheet: ^PcxImage;
   Images: SpriteImages;

begin
     New(SpriteSheet, Init('img\marty.pcx'));

     Images[0] := SpriteSheet^.SpriteAt(0, 0, 16, 16);
     Images[1] := SpriteSheet^.SpriteAt(16, 0, 16, 16);
     Images[2] := SpriteSheet^.SpriteAt(32, 0, 16, 16);

     Dispose(SpriteSheet, Destroy);

     New(EnemyObj, Init(TheScreen, X, Y, Images, 3, PaletteOffset));

     EnemyInstance := EnemyObj;
end;

constructor EnemySprite.Init;
begin
     inherited Init(TheScreen, InitialX, InitialY, 16, 16, TheImages, TheImagesLength);

     Direction := -1;
end;

procedure EnemySprite.Update(TheMap: PGameMap);
var
   NextX, GroundY, CollisionX: Word;
begin
     Animating := true;

     BaseSprite.Update(TheMap);

     GroundY := TheMap^.NextGroundYAt(X, X + Width, Y) - Height - 2;
     if Y < GroundY then
     begin
          Inc(Y);

          if Y > GroundY then
             Y := GroundY;

          Exit;
     end;

     NextX := X + Direction * 2;
     CollisionX := NextX;
     if Direction = 1 then
        Inc(CollisionX, Width);

     if (TheMap^.TileAt(CollisionX div TheMap^.TileWidth, Y div TheMap^.TileHeight) = 0) then
        X := NextX
     else
        Direction := Direction * -1;
end;

end.