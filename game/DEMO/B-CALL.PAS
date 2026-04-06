{ Not sure if this benchmark is worth anything }
program CallBenchmark;
uses Crt, ZenTimer;

const
     Iterations = 65536;

type
    StaticClass = object
        procedure StaticMethod;
    end;

    BaseClass = object
        constructor Init;
        procedure StaticMethod;
        procedure VirtualMethod; virtual;
    end;

    ChildClass = object(BaseClass)
        procedure VirtualMethod; virtual;
    end;

    GrandChildClass = object(ChildClass)
        procedure VirtualMethod; virtual;
    end;

    ProcRec = record
        Proc: procedure;
    end;

procedure StaticClass.StaticMethod;
begin
end;

constructor BaseClass.Init;
begin
end;

procedure BaseClass.StaticMethod;
begin
end;

procedure BaseClass.VirtualMethod;
begin
end;

procedure ChildClass.VirtualMethod;
begin
end;

procedure GrandChildClass.VirtualMethod;
begin
end;

procedure NearProcedure;
begin
end;

procedure FarProcedure; far;
begin
end;

procedure PrintResult(Name: String; T: LongInt);
begin
     WriteLn(Name:40, ' ', T:8, ' (', (T / Iterations):0:3, ' avg)');
end;

var
   i: LongInt;
   StaticObj: StaticClass;
   BaseObj: BaseClass;
   ChildObj: ChildClass;
   GrandChildObj: GrandChildClass;
   Rec: ProcRec;

begin
     ClrScr;

     WriteLn('Running ', Iterations, ' iterations per case...');
     WriteLn;

     BaseObj.Init;
     ChildObj.Init;
     GrandChildObj.Init;
     Rec.Proc := FarProcedure;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         NearProcedure;
     end;
     PrintResult('Near procedure', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         FarProcedure;
     end;
     PrintResult('Far procedure', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         StaticObj.StaticMethod;
     end;
     PrintResult('Static method (static obj)', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         BaseObj.StaticMethod;
     end;
     PrintResult('Static method (obj /wdynamic methods)', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         BaseObj.VirtualMethod;
     end;
     PrintResult('Virtual method', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         ChildObj.VirtualMethod;
     end;
     PrintResult('Virtual method (child obj)', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         GrandChildObj.VirtualMethod;
     end;
     PrintResult('Virtual method (grandchild obj)', LZTimerLap);
     LZTimerOff;

     LZTimerOn;
     for i := 0 to Iterations-1 do begin
         Rec.Proc;
     end;
     PrintResult('Procedural type (record field)', LZTimerLap);
     LZTimerOff;
end.