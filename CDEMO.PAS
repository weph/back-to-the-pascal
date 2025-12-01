program CanvasDemo;
uses Crt, Screen, VGA;

procedure Fill(P: Pointer; C: Byte; S: Word);
var
   i: Word;
begin
     for i := 0 to S - 1 do
         Move(C, Ptr(Seg(P^), Ofs(P^) + i)^, 1);
end;

var
   VGAC: Mode13;
   B: Buffer;
   SB: Canvas;
   DB: BufferedCanvas;
   Rect: Pointer;
   x, y, yo, i: Integer;
   xd, yd: Integer;
   c: Byte;

begin
     VGAC.Init;
     B.Init(640, 400);
     SB.New(320, 200);
     DB.Init(@VGAC);

     GetMem(Rect, 64000);

     c := 1;
     for y := 0 to 1 do
         for x := 0 to 1 do
         begin
              Fill(Rect, c, 64000);
              B.Draw(x * 320, y * 200, 320, 200, Rect);
              Inc(c);
         end;

     SB.Draw(0, 0, 320, 200, Rect);

     x := 0;
     y := 0;
     xd := 1;
     yd := 1;
     While not KeyPressed do
     begin
          B.CopyAreaTo(x, y, 320, 200, @DB, 0, 0);

          WaitForVRetrace;

          DB.Update;

          x := x + xd;
          if (x <= 0) or (x >= 320) then
             xd := xd * -1;

          y := y + yd;
          if (y <= 0) or (y >= 200) then
             yd := yd * -1;
     end;

     FreeMem(Rect, 64000);
     B.Destroy;
     VGAC.Destroy;
end.