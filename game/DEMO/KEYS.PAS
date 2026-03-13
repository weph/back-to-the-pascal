program KeysDemo;

uses Crt, Keyboard;

var
   i, j: LongInt;

begin
     for i := 0 to 10000 do begin
         ClrScr;

         for j := 1 to 127 do begin
             if Keys[j] then begin
                Writeln(j);
             end;
         end;
     end;
end.