unit Malloc;

interface

procedure M_Alloc(var P; Size: Word);

procedure M_Free(var P; Size: Word);

procedure M_Debug;

implementation

var
   TotalAllocated: LongInt;
   TotalFreed: LongInt;

procedure M_Alloc(var P; Size: Word);
begin
     Inc(TotalAllocated, Size);
     GetMem(Pointer(P), Size);
end;

procedure M_Free(var P; Size: Word);
begin
     Inc(TotalFreed, Size);
     FreeMem(Pointer(P), Size);
end;

procedure M_Debug;
begin
     WriteLn('Memory allocated: ', TotalAllocated);
     WriteLn('Memory freed: ', TotalFreed);
end;

end.