program BackToThePascal;
uses Crt, Strings, PcxImg, Map, Sprite, Screen, Player, Enemy, ATile;

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

begin
     Video := DoubleBufferedVGA;

     New(TheMap, Init('map.txt', Video, 8, 8));

     Running := true;

     MaxScrollX := TheMap^.Width - Video^.CanvasWidth;
     MaxScrollY := TheMap^.Height - Video^.CanvasHeight;

     Marty := MartyInstance(Video, 10, 166);

     Sprites.Init;
     Sprites.Add(Marty);
     Sprites.Add(EnemyInstance(Video, 300, 14, 2));
     Sprites.Add(EnemyInstance(Video, 10, 54, 4));

     for i := 0 to 14 do
         Sprites.Add(WaterInstance(Video, 136 + i * TheMap^.TileWidth, 192, i mod 4));

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

     VGA^.Destroy;

     Dispose(TheMap);
end.