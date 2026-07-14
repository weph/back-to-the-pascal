program TestZBufferClear;
uses Globals, Types, VGA, ModeX, PCXImg, Debug;

procedure ClearScreenAndZBuffer(Page: Byte);
begin
     SetVideoStartAddress(PageOffset[Page], 0);
     X_ClearZBuf(Page);
     X_Fill(0);
end;

procedure TestFirstColumn(Page: Byte);
var
   X, Y: Word;
   Stopwatch: PStopwatch;
begin
     for Y := 0 to LogicalScreenHeight - 1 do begin
         for X := 0 to LogicalScreenWidth - 1 do begin
             X_PutPixelZ(Page, X, Y, (LogicalScreenWidth - X) shr 3, 0);
         end;
     end;

     X_DrawZBuf(Page);

     ReadLn;

     Stopwatch := Profiler^.Stopwatch('X_ClearZBufFirstCol');
     Stopwatch^.Start;
     X_ClearZBufFirstCol(Page);
     Stopwatch^.Stop;

     X_DrawZBuf(Page);

     ReadLn;

     SetVideoStartAddress(PageOffset[Page] + 16, 0);

     ReadLn;
end;

procedure TestLastColumn(Page: Byte);
var
   X, Y: Word;
   Stopwatch: PStopwatch;
begin
     for Y := 0 to LogicalScreenHeight - 1 do begin
         for X := 0 to LogicalScreenWidth - 1 do begin
             X_PutPixelZ(Page, X, Y, X shr 3, 0);
         end;
     end;

     X_DrawZBuf(Page);

     ReadLn;

     Stopwatch := Profiler^.Stopwatch('X_ClearZBufLastCol');
     Stopwatch^.Start;
     X_ClearZBufLastCol(Page);
     Stopwatch^.Stop;

     X_DrawZBuf(Page);

     ReadLn;

     SetVideoStartAddress(PageOffset[Page] + 16, 0);

     ReadLn;
end;

procedure TestFirstRow(Page: Byte);
var
   X, Y: Word;
   Stopwatch: PStopwatch;
begin
     for Y := 0 to LogicalScreenHeight - 1 do begin
         for X := 0 to LogicalScreenWidth - 1 do begin
             X_PutPixelZ(Page, X, Y, (LogicalScreenHeight - Y) shr 3, 0);
         end;
     end;

     X_DrawZBuf(Page);

     ReadLn;

     Stopwatch := Profiler^.Stopwatch('X_ClearZBufFirstRow');
     Stopwatch^.Start;
     X_ClearZBufFirstRow(Page);
     Stopwatch^.Stop;

     X_DrawZBuf(Page);

     ReadLn;

     SetVideoStartAddress(PageOffset[Page] + 32 * PlaneWidth, 0);

     ReadLn;
end;

procedure TestLastRow(Page: Byte);
var
   X, Y: Word;
   Stopwatch: PStopwatch;
begin
     for Y := 0 to LogicalScreenHeight - 1 do begin
         for X := 0 to LogicalScreenWidth - 1 do begin
             X_PutPixelZ(Page, X, Y, Y shr 3, 0);
         end;
     end;

     X_DrawZBuf(Page);

     ReadLn;

     Stopwatch := Profiler^.Stopwatch('X_ClearZBufLastRow');
     Stopwatch^.Start;
     X_ClearZBufLastRow(Page);
     Stopwatch^.Stop;

     X_DrawZBuf(Page);

     ReadLn;

     SetVideoStartAddress(PageOffset[Page] + 32 * PlaneWidth, 0);

     ReadLn;
end;

var
   Page: Byte;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     SetVideoStartAddress(0, 0);
     X_InitZBuf;

     for Page := 0 to 1 do begin
         SetVideoStartAddress(PageOffset[Page], 0);

         ClearScreenAndZBuffer(Page);
         TestFirstColumn(Page);

         ClearScreenAndZBuffer(Page);
         TestLastColumn(Page);

         ClearScreenAndZBuffer(Page);
         TestFirstRow(Page);

         ClearScreenAndZBuffer(Page);
         TestLastRow(Page);
     end;

     SetVideoMode(3);

     Profiler^.Print;

     ReadLn;
end.