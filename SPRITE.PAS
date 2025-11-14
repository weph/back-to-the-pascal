unit Sprite;


interface

uses Screen, Map;

const
     MaxSprites = 100;

type
    SpriteImages = Array[0..10] of Pointer;

    PSprite = ^BaseSprite;
    BaseSprite = object
        private
            Screen: PCanvas;
            Background: PCanvas;
            Images: SpriteImages;
            ImagesLength: Byte;

            function OffScreen(ScrollX, ScrollY: Word): Boolean;

        public
            X, Y: Word;
            Width, Height: Byte;
            Animating: Boolean;
            Frames: Word;
            CurrentImage: Byte;

            constructor Init(
                TheScreen: PCanvas;
                InitialX, InitialY: Word;
                SpriteWidth, SpriteHeight: Byte;
                TheImages: SpriteImages;
                TheImagesLength: Byte
            );
            procedure SetPosition(NewX, NewY: Word);
            procedure Draw(ScrollX, ScrollY: Word);
            procedure Update(TheMap: PGameMap); virtual;
            procedure CaptureBackground(ScrollX, ScrollY: Word);
            procedure RedrawBackground(ScrollX, ScrollY: Word);

    end;


    SpriteCollection = object
            private
                   Sprites: Array[0..MaxSprites] of PSprite;
                   NumberOfSprites: Byte;
            public
                  constructor Init;
                  procedure Add(Sprite: PSprite);
                  procedure Draw(ScrollX, ScrollY: Word);
                  procedure Update(TheMap: PGameMap);
                  procedure CaptureBackground(ScrollX, ScrollY: Word);
                  procedure RedrawBackground(ScrollX, ScrollY: Word);
    end;



implementation

constructor BaseSprite.Init;
begin
     Screen := TheScreen;
     Background := New(PCanvas, New(SpriteWidth, SpriteHeight));
     X := InitialX;
     Y := InitialY;
     Width := SpriteWidth;
     Height := SpriteHeight;
     Images := TheImages;
     ImagesLength := TheImagesLength;
     CurrentImage := 0;
     Animating := false;
end;

function BaseSprite.OffScreen;
var
   X1, X2, Y1, Y2: Integer;
begin
     X1 := X - ScrollX;
     X2 := X1 + Width;
     Y1 := Y - ScrollY;
     Y2 := Y1 + Height;

     OffScreen := (X1 > Screen^.CanvasWidth) or
        (X2 < 0) or
        (Y1 > Screen^.CanvasHeight) or
        (Y2 < 0);
end;

procedure BaseSprite.Draw;
begin
     if OffScreen(ScrollX, ScrollY) then Exit;

     Screen^.DrawAlpha(X - ScrollX, Y - ScrollY, Width, Height, Images[CurrentImage]);
end;

procedure BaseSprite.SetPosition(NewX, NewY: Word);
begin
     X := NewX;
     Y := NewY;
end;

procedure BaseSprite.Update;
begin
     if Animating then
     begin
          Inc(Frames);

          if Frames mod 3 = 0 then
               CurrentImage := (CurrentImage + 1) mod ImagesLength;

          if Frames > 3 * ImagesLength then
             Animating := false;
     end;
end;

procedure BaseSprite.CaptureBackground;
begin
     if OffScreen(ScrollX, ScrollY) then Exit;

     Screen^.CopyAreaTo(X - ScrollX, Y - ScrollY, Width, Height, Background, 0, 0);
end;

procedure BaseSprite.RedrawBackground;
begin
     if OffScreen(ScrollX, ScrollY) then Exit;

     Background^.CopyAreaTo(0, 0, Width, Height, Screen, X - ScrollX, Y - ScrollY);
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
              Sprites[i]^.Draw(ScrollX, ScrollY);
end;

procedure SpriteCollection.Update(TheMap: PGameMap);
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
              Sprites[i]^.Update(TheMap);
end;

procedure SpriteCollection.CaptureBackground;
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
              Sprites[i]^.CaptureBackground(ScrollX, ScrollY);
end;

procedure SpriteCollection.RedrawBackground;
var
   i: Byte;
begin
     if NumberOfSprites > 0 then
          for i := 0 to NumberOfSprites - 1 do
              Sprites[i]^.RedrawBackground(ScrollX, ScrollY);
end;

end.