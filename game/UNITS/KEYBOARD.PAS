unit Keyboard;

interface

var
   Keys: Array[1..127] of Boolean;

procedure EnableKeyboardHandler;

procedure DisableKeyboardHandler;

implementation

uses Dos, Crt;

var
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

procedure EnableKeyboardHandler;
begin
     GetIntVec($09, @PrevIntHandler);
     SetIntVec($09, @IntHandler);
end;

procedure DisableKeyboardHandler;
begin
     SetIntVec($09, @PrevIntHandler);
end;

end.