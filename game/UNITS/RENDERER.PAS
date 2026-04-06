unit Renderer;

interface

uses Types, Sprite, TopDown;

procedure R_Init(_MapRenderer: PTopDownMapRenderer);

procedure R_AddSprite(Sprite: PSprite);

procedure R_InitScreen;

procedure R_Render(Page: Byte; Scroll: TCoordinate);

procedure R_Destroy;

implementation

uses Globals, ModeX, Image, PCXImg, VGA;

var
   Sprites: array[0..255] of PSprite;
   NumSprites: Byte;
   DirtyRects: array[0..1,0..255] of TDirtyRect;
   MapRenderer: PTopDownMapRenderer;

procedure SaveDirtyRect(Page: Byte; X, Y: Word; var Target: TDirtyRect);
begin
     Target.X := X;
     Target.Y := Y;

     X_CopyToSysMem(
         Page,
         Target.X,
         Target.Y,
         Target.Image^.Width,
         Target.Image^.Height,
         Target.Image^.Data
     );
end;

procedure DrawDirtyRect(Page: Byte; DirtyRect: TDirtyRect);
begin
     X_DrawOpaque(
         Page,
         DirtyRect.X,
         DirtyRect.Y,
         DirtyRect.Image
     );
end;

procedure R_AddSprite(Sprite: PSprite);
var
   Page: Byte;
begin
     Sprites[NumSprites] := Sprite;

     for Page := 0 to 1 do begin
         New(DirtyRects[Page][NumSprites].Image, New(Sprite^.Width, Sprite^.Height));
     end;

     Inc(NumSprites);
end;

procedure FreeDirtyRects;
var
   Page, Sprite: Byte;
begin
     for Page := 0 to 1 do begin
         for Sprite := 0 to NumSprites - 1 do begin
             Dispose(DirtyRects[Page][Sprite].Image, Destroy);
         end;
     end;
end;

procedure R_Init(_MapRenderer: PTopDownMapRenderer);
begin
     MapRenderer := _MapRenderer;
end;

procedure R_InitScreen;
var
   Offset: TCoordinate;
   Scroll: TCoordinate;
   Page, Sprite: Byte;
begin
     Offset.X := 0;
     Offset.Y := 0;
     Scroll.X := 0;
     Scroll.Y := 0;

     for Page := 0 to 1 do begin
         MapRenderer^.Draw(Page, Offset, Scroll);

         for Sprite := 0 to NumSprites - 1 do begin
             with Sprites[Sprite]^ do begin
                  SaveDirtyRect(Page, X, Y, DirtyRects[Page][Sprite]);
             end;
         end;
     end;
end;

procedure R_Render(Page: Byte; Scroll: TCoordinate);
var
   Sprite: Byte;
   DRY: Word;
begin
     for Sprite := 0 to NumSprites - 1 do begin
         DrawDirtyRect(Page, DirtyRects[Page][Sprite]);
     end;

     MapRenderer^.Update(Page, Scroll);

     for Sprite := 0 to NumSprites - 1 do begin
         with Sprites[Sprite]^ do begin
              if Z = 65535 then DRY := Y else DRY := Y - Z;

              SaveDirtyRect(Page, X, DRY, DirtyRects[Page][Sprite]);
         end;
     end;

     for Sprite := 0 to NumSprites - 1 do begin
         Sprites[Sprite]^.Draw(Page);
         MapRenderer^.DrawLayersCoveringSprite(Page, Scroll, Sprites[Sprite]);
     end;
end;

procedure R_Destroy;
begin
     FreeDirtyRects;
end;

begin
     NumSprites := 0;
end.