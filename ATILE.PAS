unit ATile;



interface

uses Sprite, Map, PcxImg, Screen;

type
    AnimatedTile = object(BaseSprite)
                public
                      constructor Init(
                                  TheScreen: PCanvas;
                                  InitialX, InitialY: Word;
                                  TheImages: SpriteImages;
                                  TheImagesLength: Byte;
                                  AnimationOffset: Byte
                      );

                      procedure Update(TheMap: PGameMap); virtual;

    end;

function WaterInstance(TheScreen: PCanvas; X, Y: Word; AnimationOffset: Byte): PSprite;


implementation

function WaterInstance;
var
   Water: ^AnimatedTile;
   WaterImages: SpriteImages;
   TilesImage: ^PcxImage;
begin
     New(TilesImage, Init('img\tiles.pcx'));

     WaterImages[0] := TilesImage^.SpriteAt(0, 16, 8, 8);
     WaterImages[1] := TilesImage^.SpriteAt(8, 16, 8, 8);
     WaterImages[2] := TilesImage^.SpriteAt(16, 16, 8, 8);
     WaterImages[3] := TilesImage^.SpriteAt(24, 16, 8, 8);

     Dispose(TilesImage, Destroy);

     New(Water, Init(TheScreen, X, Y, WaterImages, 4, AnimationOffset));

     WaterInstance := Water;
end;


constructor AnimatedTile.Init;
begin
     inherited Init(TheScreen, InitialX, InitialY, 8, 8, TheImages, TheImagesLength);

     CurrentImage := AnimationOffset;
end;

procedure AnimatedTile.Update(TheMap: PGameMap);
begin
     Animating := true;

     BaseSprite.Update(TheMap);
end;


end.