program Palette;
uses Crt, VGA, Screen, PCXImg;

var
   Video: PCanvas;
   Highlight: PCanvas;
   Color: TColor;
   Tiles: PCXImage;
   i: Byte;
   TileWidth, TileHeight: Byte;
   X, Y: Word;
   MaxX, MaxY: Word;
   P: Word;
   Tile: Pointer;
   Running: Boolean;

procedure PutChar(X, Y: Word; C: Char);
var
   Cx, Cy, Mask, Color: Byte;
   Chars: array[0..255*8] of byte absolute $f000:$fa6e;
   Vga: array[0..63999] of byte absolute $a000:$0000;
begin
     for Cy := 0 to 7 do
     begin
          Mask := $80;
          for Cx := 0 to 7 do
          begin
               if Chars[Ord(C) * 8 + Cy] and Mask = Mask then
                   Color := 16
               else
                   Color := 0;

               Vga[(Y + Cy) * 320 + X + Cx] := Color;

               Mask := Mask shr 1;
          end;
     end;
end;

procedure PutString(X, Y: Word; S: String);
var
   i: Integer;
begin
     for i := 1 to Length(S) do
         PutChar(X + (i - 1) * 8, Y, S[i]);
end;


begin
     Video := DoubleBufferedVGACanvas;
     Video^.Fill(0);

     Tiles.Init('img\tiles2.pcx');
     TileWidth := 16;
     TileHeight := 16;

     MaxX := Tiles.Width div TileWidth;
     MaxY := Tiles.Height div TileHeight;

     for i := 0 to 255 do
         SetColor(i, Tiles.Palette[i]);

     Highlight := InMemoryCanvas(TileWidth, TileHeight);
     Highlight^.Fill(31);

     Video^.Draw(0, 0, Tiles.Width, Tiles.Height, Tiles.Data);

     X := 0;
     Y := 0;
     i := 0;
     P := 0;
     Running := true;
     while Running do
     begin
          X := (P mod MaxX) * TileWidth;
          Y := (P div MaxX) * TileHeight;

          Inc(i);

          if i mod 2 = 0 then
             Highlight^.CopyAreaTo(0, 0, TileWidth, TileHeight, Video, X, Y)
          else
             Video^.Draw(0, 0, Tiles.Width, Tiles.Height, Tiles.Data);

          Video^.Update;

          PutString(0, 192, Chr(Ord('0') + P));

          Delay(100);

          if not KeyPressed then
             continue;

          case ReadKey of
               'q': Running := false;
               'd': P := (P + 1) mod (MaxX * MaxY);
               'a': P := (P - 1) mod (MaxX * MaxY);
               'w': P := (P - MaxX) mod (MaxX * MaxY);
               's': P := (P + MaxX) mod (MaxX * MaxY);
          end;
     end;

     Dispose(Video, Destroy);
end.