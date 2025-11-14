program MapDemo;
uses Screen, Map, Crt;

var
   TheMap: GameMap;
   Buffer: Canvas;
   VGA: Mode13;
   Video: BufferedCanvas;
   VScreen: Canvas;
   Sx, Sy, Dx, Dy: Integer;
   Running: Boolean;
   Key: Char;

begin
     VScreen.New(320, 200);
     {Buffer.New(320, 200);}
     VGA.Init;

     {Video.Init(@Buffer, @VGA);}

     TheMap.Init('map.txt', @VScreen);

     {TheMap.Draw;}

     {Sx := 314;}
     Sx := 0;
     Sy := 50;
     Dx := 3;
     Dy := 3;
     Running := True;

     TheMap.Draw(Sx, Sy);

     {Sx := 320;}

     while Running do
     begin
          VScreen.CopyAreaTo(
              0, 0,
              VScreen.CanvasWidth, VScreen.CanvasHeight,
              @VGA,
              (VGA.CanvasWidth - VScreen.CanvasWidth) div 2,
              (VGA.CanvasHeight - VScreen.CanvasHeight) div 2
          );
          TheMap.Update(Sx, Sy);
          {Video.Update;}

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

          if (Sx + Dx < 0) or (Sx + Dx > (TheMap.Width - VScreen.CanvasWidth)) then
             Dx := Dx * -1;


          if (Sy + Dy < 0) or (Sy + Dy > (TheMap.Height - VScreen.CanvasHeight)) then
             Dy := Dy * -1;

          Inc(Sx, Dx);
          Inc(Sy, Dy);
     end;

     VGA.Destroy;
end.