program VMemCpy;
uses Globals, VGA, ModeX, Image, Debug;

procedure ProfileCopy(Title: String; Image: PImage);
var
   SW: PStopwatch;
begin
     SW := Profiler^.Stopwatch(Title);
     SW^.Start;

     X_CopyToSysMem(0, 0, 0, Image^.Width, Image^.Height, Image^.Data);

     SW^.Stop;
end;

var
   X, Y, i: Word;
   Copy8x8, Copy16x16, Copy32x32, Copy64x64: PImage;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     SetVideoStartAddress(0, 0);

     X_Fill(0);

     New(Copy8x8, New(8, 8));
     New(Copy16x16, New(16, 16));
     New(Copy32x32, New(32, 32));
     New(Copy64x64, New(64, 64));

     for Y := 0 to 15 do begin
         for X := 0 to 15 do begin
             X_PutPixel(0, X, Y, Y * 16 + X);
         end;
     end;

     for Y := 0 to 15 do begin
         for X := 0 to 31 do begin
             X_PutPixel(0, X, 32 + Y, X);
         end;
     end;

     X_CopyToSysMem(0, 0, 0, 8, 8, Copy8x8^.Data);
     X_CopyToSysMem(0, 0, 0, 16, 16, Copy16x16^.Data);

     for i := 0 to 10 do begin
         X_DrawOpaque(0, 80 + i, i * 8, Copy8x8);
         X_DrawOpaque(0, 160 + i, i * 16, Copy16x16);
     end;

     for i := 0 to 13 do begin
         Copy16x16^.Fill(0);

         X_CopyToSysMem(0, i, 32, 16, 16, Copy16x16^.Data);

         X_DrawOpaque(0, 48 + i, i * 16, Copy16x16);
     end;

     ProfileCopy('8x8', Copy8x8);     { DOSBox: 0.39ms }
     ProfileCopy('16x16', Copy16x16); { DOSBox: 0.59ms }
     ProfileCopy('32x32', Copy32x32); { DOSBox: 0.99ms }
     ProfileCopy('64x64', Copy64x64); { DOSBox: 0.182ms }

     ReadLn;
     SetVideoMode(3);

     Profiler^.Print;

     ReadLn;

     Dispose(Copy8x8, Destroy);
     Dispose(Copy16x16, Destroy);
     Dispose(Copy32x32, Destroy);
     Dispose(Copy64x64, Destroy);
end.