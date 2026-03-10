unit Debug;


interface

type
    FpsInfo = object
        private
            SampleSize: Word;
            Frames: Word;
            LastTs: LongInt;
        public
            CurrentFps: Real;
            constructor Init(TheSampleSize: Word);
            procedure Update;
    end;

    PStopwatch = ^TStopwatch;
    TStopwatch = object
        Title: String;
        Duration: LongInt;

        constructor Init(TheTitle: String);
        procedure Start;
        procedure Stop;
    end;

    PProfilerNode = ^TProfilerNode;
    TProfilerNode = record
        Stopwatch: PStopwatch;
        Next: PProfilerNode;
    end;

    PProfiler = ^TProfiler;
    TProfiler = object
        Head, Tail: PProfilerNode;

        constructor Init;
        function Stopwatch(TheTitle: String): PStopwatch;
        procedure Print;
    end;

var
   Profiler: PProfiler;

function Timestamp: LongInt;

implementation

uses Dos, Drivers, VGA, ZenTimer;

constructor TProfiler.Init;
begin
     Head := nil;
     Tail := nil;
end;

function TProfiler.Stopwatch;
var
   Next: PProfilerNode;
   Result: PStopwatch;
begin
    New(Result, Init(TheTitle));

    New(Next);
    Next^.Stopwatch := Result;
    Next^.Next := nil;

    if Head = nil then begin
        Head := Next;
        Tail := Next;
    end else begin
        Tail^.Next := Next;

        Tail := Next;
    end;

    Stopwatch := Result;
end;

procedure TProfiler.Print;
var
   Current: PProfilerNode;
   Duration: LongInt;
begin
     Current := Head;

     while Current <> nil do begin
           Duration := Current^.Stopwatch^.Duration;

           WriteLn(
               Current^.Stopwatch^.Title,
               ': ',
               Duration div 1000,
               '.',
               Duration mod 1000,
               'ms'
           );


           Current := Current^.Next;
     end;
end;

constructor TStopwatch.Init;
begin
     Title := TheTitle;
end;

procedure TStopwatch.Start;
begin
     LZTimerOn;
end;

procedure TStopwatch.Stop;
begin
     Duration := LZTimerLap;
     LZTimerOff;
end;

function Timestamp;
var
   Hour, Min, Sec, Sec100: Word;
begin
     GetTime(Hour, Min, Sec, Sec100);

     Timestamp := LongInt(Hour) * 360000 +
        LongInt(Min) * 6000 +
        LongInt(Sec) * 100 +
        LongInt(Sec100);
end;

constructor FpsInfo.Init;
begin
     SampleSize := TheSampleSize;
     Frames := 0;
     LastTs := Timestamp;
     CurrentFps := 0;
end;

procedure FpsInfo.Update;
var
   NextTs: LongInt;
begin
     Inc(Frames);

     if Frames < SampleSize then
        Exit;

     NextTs := Timestamp;

     CurrentFps := Frames / (NextTs - LastTs) * 100;
     LastTs := NextTs;
     Frames := 0;
end;

begin
     New(Profiler, Init);
end.