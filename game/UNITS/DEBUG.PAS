unit Debug;

interface

uses
    Sprite,
    Types;

type
    FpsInfo = object (TSprite)
    private
        SampleSize: Word;
        Frames: Word;
        LastTs: LongInt;
    public
        CurrentFps: Real;
        constructor Init(TheSampleSize: Word);
        procedure Update(Page: Byte; Frame: LongInt); virtual;
        procedure Draw(Page: Byte); virtual;
    end;

    PStopwatch = ^TStopwatch;
    TStopwatch = object
        Title: string;
        StartedAt: LongInt;
        LoggedStart: Boolean;

        constructor Init(TheTitle: string);
        procedure LogStart;
        procedure Stop;
    end;

procedure PrintProfile;

function Timestamp: LongInt;

implementation

uses
    Dos,
    Drivers,
    Strings,
    VGA,
    ZenTimer,
    ModeX;

var
    F: Text;
    RunningStopwatches: Byte;
    Indent: array[0..15] of string[32];
    PrevExitProc: Pointer;

procedure Log(Line: string; Duration: LongInt);
begin
    WriteLn(F, Line, ': ', Duration div 1000, '.', Duration mod 1000, 'ms');
end;

constructor TStopwatch.Init;
begin
    Title := TheTitle;
    StartedAt := LZTimerLap;
    LoggedStart := false;
    Inc(RunningStopwatches);
end;

procedure TStopwatch.LogStart;
begin
    LoggedStart := true;
    WriteLn(F, Indent[RunningStopwatches - 1], Title);
end;

procedure TStopwatch.Stop;
var
    Duration: LongInt;
    Line: string;
begin
    Duration := LZTimerLap - StartedAt;

    Dec(RunningStopwatches);

    if LoggedStart then begin
        WriteLn(F, Indent[RunningStopwatches], '--> ', Duration div 1000, '.', Duration mod 1000, 'ms');
    end
    else begin
        WriteLn(F, Indent[RunningStopwatches], Title, ': ', Duration div 1000, '.', Duration mod 1000, 'ms');
    end;
end;

function Timestamp;
var
    Hour, Min, Sec, Sec100: Word;
begin
    GetTime(Hour, Min, Sec, Sec100);

    Timestamp := LongInt(Hour) * 360000 + LongInt(Min) * 6000 + LongInt(Sec) * 100 + LongInt(Sec100);
end;

constructor FpsInfo.Init;
begin
    inherited Init(0, 0, 65535, 48, 16);

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

procedure FpsInfo.Draw(Page: Byte);
var
    S: string;
begin
    Str(CurrentFps: 0: 3, S);
    X_PutString(Page, X, Y, S);
end;

procedure InitializeIndents;
var
    i: Byte;
    s: string;
begin
    s := '';
    for i := 0 to 15 do begin
        Indent[i] := s;

        s := Concat(s, '  ');
    end;
end;

procedure PrintProfile;
var
    Line: string;
begin
    Reset(F);

    while not Eof(F) do begin
        ReadLn(F, Line);
        Writeln(Line);
    end;
end;

procedure CloseLog; far;
begin
    ExitProc := PrevExitProc;

    Close(F);
end;

begin
    ExitProc := @CloseLog;

    RunningStopwatches := 0;

    InitializeIndents;

    Assign(F, 'profile.log');
    Rewrite(F);

    LZTimerOn;
end.
