program CodeGen;

uses
    Drivers;

function DrawFuncName(Prefix: string; Mask: Byte): string;
const
    Template = '_%02x';
var
    Result: string;
    Params: array[0..0] of LongInt;
begin
    Params[0] := Mask;
    FormatStr(Result, Template, Params);
    DrawFuncName := Prefix + Result;
end;

procedure GenerateLookupTable(var Target: Text; Prefix: string);
var
    Mask: Byte;
begin
    Write(Target, Prefix, 'Funcs DW ');

    for Mask := 0 to 255 do begin
        Write(Target, DrawFuncName(Prefix, Mask));

        if Mask < 255 then begin
            if ((Mask + 1) mod 8) = 0 then begin
                WriteLn(Target);
                Write(Target, '          DW ');
            end
            else begin
                Write(Target, ', ');
            end;
        end;
    end;

    WriteLn(Target);
    WriteLn(Target);
end;

procedure GenerateDrawFunc(var Target: Text; Prefix: string; ModifyZBuffer: Boolean; Mask: Byte);
var
    Bit: Byte;
    Current: Byte;
    OpaqueBits: array[0..7] of Byte;
    NumOpaqueBits: Byte;
begin
    Bit := 1;
    NumOpaqueBits := 0;

    for Bit := 7 downto 0 do begin
        Current := 1 shl Bit;
        if (Mask and Current) = Current then begin
            OpaqueBits[NumOpaqueBits] := 7 - Bit;
            Inc(NumOpaqueBits);
        end;
    end;

    Writeln(Target, DrawFuncName(Prefix, Mask), ':');

    if NumOpaqueBits > 0 then begin
        for Bit := 0 to NumOpaqueBits - 1 do begin
            WriteLn(Target, '@@Bit', OpaqueBits[Bit], ':');
            WriteLn(Target, '    cmp dh, [gs:di+', OpaqueBits[Bit], ']');

            if Bit < NumOpaqueBits - 1 then begin
                WriteLn(Target, '    jb @@Bit', OpaqueBits[Bit + 1]);
            end
            else begin
                WriteLn(Target, '    jb @@End');
            end;

            if ModifyZBuffer then begin
                WriteLn(Target, '    mov [gs:di+', OpaqueBits[Bit], '], dh');
            end;

            WriteLn(Target, '    mov al, [si+', Bit, ']');
            WriteLn(Target, '    mov [es:di+', OpaqueBits[Bit], '], al');
        end;

        WriteLn(Target, '@@End:');
        WriteLn(Target, '    add si, ', NumOpaqueBits);
    end;

    WriteLn(Target, '    ret');
    WriteLn(Target);
end;

procedure GenerateFile(Filename: string; Prefix: string; ModifyZBuffer: Boolean);
var
    Mask: Byte;
    Target: Text;
begin
    Assign(Target, Filename);
    Rewrite(Target);

    GenerateLookupTable(Target, Prefix);
    for Mask := 0 to 255 do begin
        GenerateDrawFunc(Target, Prefix, ModifyZBuffer, Mask);
    end;

    Close(Target);
end;

begin
    GenerateFile('UNITS\DRAW.ASM', 'Draw', false);
    GenerateFile('UNITS\DRAWZ.ASM', 'DrawZ', true);
end.
