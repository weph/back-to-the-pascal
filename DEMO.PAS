program Demo;
uses Screen, Crt, PCXImg;

const
     NumStars = 500;

var
   Video: PCanvas;
   Background: PCanvas;
   BGX: Word;
   Image: PCXImage;
   Marty: Pointer;
   MX, MY: Word;
   MDX, MDY: Integer;
   i: Word;
   Stars: Array[0..NumStars] of record
          X, Y: Word;
   end;

begin
     Video := DoubleBufferedVGA;

     for i := 0 to NumStars do
     begin
          Stars[i].X := Random(Video^.CanvasWidth);
          Stars[i].Y := Random(Video^.CanvasHeight);
     end;

     Background := InMemory(640, 200);
     Image.Init('img\bg1.pcx');
     Background^.Draw(0, 0, Image.Width, Image.Height, Image.Data);
     Image.Destroy;
     Image.Init('img\bg2.pcx');
     Background^.Draw(320, 0, Image.Width, Image.Height, Image.Data);
     Image.Destroy;

     Image.Init('img\marty.pcx');
     Marty := Image.SpriteAt(0, 0, 16, 16);

     BGX := 0;
     MX := 0;
     MY := 0;
     MDX := 3;
     MDY := 1;
     while not KeyPressed do
     begin
          Background^.CopyAreaTo(BGX, 0, Video^.CanvasWidth, Video^.CanvasHeight, Video, 0, 0);

          for i := 0 to NumStars do
          begin
               Video^.PutPixel(Stars[i].X, Stars[i].Y, 7);

               Stars[i].Y := (Stars[i].Y + 1) mod Video^.CanvasHeight;
          end;

          Video^.DrawAlpha(MX, MY, 16, 16, Marty);

          Video^.Update;

          BGX := (BGX + 1) mod (Background^.CanvasWidth - Video^.CanvasWidth);

          if ((MX + MDX) <= 0) or ((MX + MDX) > Video^.CanvasWidth - 16) then
             MDX := MDX * -1;

          if ((MY + MDY) <= 0) or ((MY + MDY) > Video^.CanvasHeight - 16) then
             MDY := MDY * -1;

          Inc(MX, MDX);
          Inc(MY, MDY);
     end;

     Dispose(Video, Destroy);
end.