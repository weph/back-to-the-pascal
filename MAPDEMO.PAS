program MapDemo;
uses Screen, Map, Crt, Debug;

var
   TheMap: GameMap;
   MiniMap: PCanvas;
   Video: PCanvas;
   Sx, Sy, Dx, Dy: Integer;
   Running: Boolean;
   Key: Char;
   Fps: FpsInfo;
   X, Y: Word;

begin
     MiniMap := InMemory(200, 120);
     Video := DoubleBufferedVGA;

     Fps.Init(10);

     TheMap.Init('map.txt', MiniMap, 8, 8);

     {TheMap.Draw;}

     {Sx := 314;}
     Sx := 0;
     Sy := 0;
     Dx := 1;
     Dy := 1;
     Running := True;

     TheMap.Draw(Sx, Sy);

     {Sx := 320;}

     while Running do
     begin
          Video^.Fill(0);
          TheMap.MapCanvas.CopyAreaTo(
              0, 0,
              TheMap.MapCanvas.CanvasWidth, TheMap.MapCanvas.CanvasHeight,
              Video,
              80 - (TheMap.PrevX mod 8),
              40 - (TheMap.PrevY mod 8));

          for X := 80 to 80 + MiniMap^.CanvasWidth - 1 do
          begin
              Video^.PutPixel(X, 40, 10);
              Video^.PutPixel(X, 40 + MiniMap^.CanvasHeight - 1, 10);
          end;

          for Y := 40 to 40 + MiniMap^.CanvasHeight - 1 do
          begin
              Video^.PutPixel(80, Y, 10);
              Video^.PutPixel(80 + MiniMap^.CanvasWidth - 1, Y, 10);
          end;

          TheMap.Update(Sx, Sy);
          Video^.Update;

          Fps.Update;
          Fps.Show;

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'w': Dec(Dy, 3);
                    's': Inc(Dy, 3);
                    'a': Dec(Sx, Abs(Dx));
                    'd': Inc(Sx, Abs(Dx));
               end;
          end;

          if (Sx + Dx < 0) or (Sx + Dx > (TheMap.Width - MiniMap^.CanvasWidth)) then
             Dx := Dx * -1;


          if (Sy + Dy < 0) or (Sy + Dy > (TheMap.Height - MiniMap^.CanvasHeight)) then
             Dy := Dy * -1;

          Inc(Sx, Dx);
          Inc(Sy, Dy);
     end;

     Dispose(Video, Destroy);
end.