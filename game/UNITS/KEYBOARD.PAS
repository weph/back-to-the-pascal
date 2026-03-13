unit Keyboard;

interface

var
   Keys: Array[1..127] of Boolean;

implementation

uses Dos, Crt;

var
   PrevExitProc: Pointer;
   PrevIntHandler: Procedure;

procedure IntHandler; interrupt;
var
   ScanCode, KeyCode: Byte;
begin
     ScanCode := Port[$60];
     Keys[ScanCode mod 128] := ScanCode < 128;

     PrevIntHandler;

     Mem[$0040:$001a] := Mem[$0040:$001c];
end;

{$F+}
procedure RestoreHandler;
begin
     ExitProc := PrevExitProc;
     SetIntVec($09, @PrevIntHandler);
end;
{$F-}

begin
     PrevExitProc := ExitProc;
     ExitProc := @RestoreHandler;

     GetIntVec($09, @PrevIntHandler);
     SetIntVec($09, @IntHandler);
end.