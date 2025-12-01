program BackToThePascal;
uses Crt, Strings, PcxImg, Map, Sprite, Screen, Player, Enemy, ATile, Debug;

var
   i: Word;
   Running: Boolean;
   Marty: ^MartySprite;
   Key: Char;
   Sprites: SpriteCollection;
   MaxScrollX, MaxScrollY: Word;
   TheMap: ^GameMap;
   Video: PCanvas;
   ScrollX, ScrollY: Word;
   Fps: FpsInfo;

begin
     Fps.Init(10);
     Video := DoubleBufferedVGACanvas;

     New(TheMap, Init('map.txt', Video, 'img\tiles2.pcx', 16, 16));

     Running := true;

     MaxScrollX := TheMap^.Width - Video^.CanvasWidth;
     MaxScrollY := TheMap^.Height - Video^.CanvasHeight;

     Marty := MartyInstance(Video, 20, 180);

     Sprites.Init;
     Sprites.Add(Marty);
     {Sprites.Add(EnemyInstance(Video, 300, 14, 2));
     Sprites.Add(EnemyInstance(Video, 20, 54, 4));}

     TheMap^.Draw(0, 0);
     while Running do
     begin
          if Marty^.X > Video^.CanvasWidth div 2
             then ScrollX := Marty^.X - Video^.CanvasWidth div 2
             else ScrollX := 0;

          if ScrollX > MaxScrollX then ScrollX := MaxScrollX;

          if Marty^.Y > Video^.CanvasHeight div 2
             then ScrollY := Marty^.Y - Video^.CanvasHeight div 2
             else ScrollY := 0;

          if ScrollY > MaxScrollY then ScrollY := MaxScrollY;


          TheMap^.Update(ScrollX, ScrollY);

          Sprites.CaptureBackground(ScrollX, ScrollY);

          Sprites.Draw(ScrollX, ScrollY);

          Video^.Update;
          Fps.Update;
          Fps.Show;

          Sprites.RedrawBackground(ScrollX, ScrollY);

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'w': Marty^.Ollie;
                    'a': Marty^.Push(-1);
                    'd': Marty^.Push(1);
               end;
          end;

          Sprites.Update(TheMap);
     end;

     Dispose(Video, Destroy);
     Dispose(TheMap);
end.