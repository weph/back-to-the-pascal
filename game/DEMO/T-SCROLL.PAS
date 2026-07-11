{ Test program that draws images at an offset in video memory }
program TestScroll;
uses Globals, Types, VGA, ModeX, PCXImg, Image;

var
   SourceImage: PCXImage;
   TileOpaque, TileAlpha: PImage;
   ScrollPos: TCoordinate;
   Page: Byte;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     SetVideoStartAddress(0, 0);

     SourceImage.Init('demo\b-draw.pcx');

     TileOpaque := SourceImage.ImageAt(0, 0, 16, 16);
     TileAlpha := SourceImage.ImageAt(16, 0, 16, 16);

     for Page := 0 to 1 do begin
         X_Fill(0);

         ScrollPos.X := 640;
         ScrollPos.Y := 480;
         X_SetScrollOffset(Page, ScrollPos);

         X_Draw16x16Opaque(Page, 0, 0, TileOpaque);

         X_DrawOpaque(Page, 152, 112, TileOpaque);

         X_DrawAlphaZ(Page, 304, 0, 255, TileAlpha);
         X_DrawAlpha(Page, 304, 224, 255, TileAlpha);

         SetVideoStartAddress(
             PageOffset[Page] + (ScrollPos.X shr 2) + ScrollPos.Y * PlaneWidth,
             0
         );

         ReadLn;
     end;

     SetVideoMode(3);
end.