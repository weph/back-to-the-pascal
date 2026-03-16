program VMemCpy;
uses VGA, ModeX, Image;

var
   X, Y, i: Word;
   Copy8x8, Copy16x16: PImage;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     SetVideoStartAddress(0, 0);

     New(Copy8x8, New(8, 8));
     New(Copy16x16, New(16, 16));

     for Y := 0 to 15 do begin
         for X := 0 to 15 do begin
             X_PutPixel(0, X, Y, Y * 16 + X);
         end;
     end;

     {X_CopyToSysMem(0, 0, 0, 8, 8, Copy8x8^.Data);
     X_CopyToSysMem(0, 0, 0, 16, 16, Copy16x16^.Data);}

     {for i := 0 to 10 do begin
         X_DrawOpaque(0, 80 + i, i * 8, Copy8x8);
         X_DrawOpaque(0, 160 + i, i * 16, Copy16x16);
     end;}

     for i := 0 to 15 do begin
         Copy16x16^.Fill(0);
         X_CopyToSysMem(0, i, 0, 16, 16, Copy16x16^.Data);
         X_DrawOpaque(0, 32 + i, i * 16, Copy16x16);
     end;

     ReadLn;
     SetVideoMode(3);

     Dispose(Copy8x8, Destroy);
     Dispose(Copy16x16, Destroy);
end.