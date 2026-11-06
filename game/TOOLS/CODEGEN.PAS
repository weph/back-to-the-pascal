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

procedure GenerateLookupTable(var F: Text; Prefix: string);
var
    Mask: Byte;
begin
    Write(F, Prefix, 'Funcs DW ');

    for Mask := 0 to 255 do begin
        Write(F, DrawFuncName(Prefix, Mask));

        if Mask < 255 then begin
            if ((Mask + 1) mod 8) = 0 then begin
                WriteLn(F);
                Write(F, '          DW ');
            end
            else begin
                Write(F, ', ');
            end;
        end;
    end;

    WriteLn(F);
    WriteLn(F);
end;

procedure GeneratePixelCode(
    var F: Text;
    ZBufLocation: string;
    var JumpTarget: Byte;
    ZBufOffs: Byte;
    var VideoOffs: Byte;
    ModifyZBuffer: Boolean
);
begin
    WriteLn(F, '    cmp dh, ', ZBufLocation);
    WriteLn(F, '    jb @@Target', JumpTarget);

    if ModifyZBuffer then begin
        WriteLn(F, '    mov [gs:di+', ZBufOffs, '], dh');
    end;

    WriteLn(F, '    mov al, [si+', VideoOffs, ']');
    WriteLn(F, '    mov [es:di+', ZBufOffs, '], al');

    Inc(VideoOffs);
end;

function GsDiAt(Offset: Byte): string;
var
    S: string;
begin
    Str(Offset, S);
    GsDiAt := '[gs:di+' + S + ']';
end;

procedure GenerateJumpTarget(var F: Text; var JumpTarget: Byte);
begin
    WriteLn(F, '@@Target', JumpTarget, ':');
    Inc(JumpTarget);
end;

procedure GenerateDrawFunc(var F: Text; Prefix: string; ModifyZBuffer: Boolean; Mask: Byte);
var
    Bit: Byte;
    Current: Byte;
    JumpTarget: Byte;
    Pixel: Byte;
    Nibble: Byte;
    Bits: array[0..7] of Boolean;
    Offset: Byte;
begin
    for Bit := 0 to 7 do begin
        Current := 1 shl Bit;

        Bits[7 - Bit] := (Mask and Current) = Current;
    end;

    Writeln(F, DrawFuncName(Prefix, Mask), ':');

    Pixel := 0;
    JumpTarget := 0;

    for Nibble := 0 to 1 do begin
        Offset := Nibble * 4;

        { Only bits 0 and 1 are set => load word into bx }
        if Bits[Offset + 0] and Bits[Offset + 1] and not Bits[Offset + 2] and not Bits[Offset + 3] then begin
            GenerateJumpTarget(F, JumpTarget);
            WriteLn(F, '    mov bx, ', GsDiAt(Offset));
            GeneratePixelCode(F, 'bl', JumpTarget, Offset + 0, Pixel, ModifyZBuffer);

            GenerateJumpTarget(F, JumpTarget);
            if not Bits[Offset + 0] then
                WriteLn(F, '    mov bx, ', GsDiAt(Offset));
            GeneratePixelCode(F, 'bh', JumpTarget, Offset + 1, Pixel, ModifyZBuffer);
        end
        { At least one lower and one upper bit is set => load double word into ebx }
        else if ((Bits[Offset + 0] or Bits[Offset + 1]) and (Bits[Offset + 2] or Bits[Offset + 3])) then begin
            if Bits[Offset + 0] then begin
                GenerateJumpTarget(F, JumpTarget);
                WriteLn(F, '    mov ebx, ', GsDiAt(Offset));
                GeneratePixelCode(F, 'bl', JumpTarget, Offset + 0, Pixel, ModifyZBuffer);
            end;

            if Bits[Offset + 1] then begin
                GenerateJumpTarget(F, JumpTarget);
                if not Bits[Offset + 0] then
                    WriteLn(F, '    mov ebx, ', GsDiAt(Offset));
                GeneratePixelCode(F, 'bh', JumpTarget, Offset + 1, Pixel, ModifyZBuffer);
            end;

            if Bits[Offset + 2] then begin
                GenerateJumpTarget(F, JumpTarget);
                WriteLn(F, '    shr ebx, 16');
                GeneratePixelCode(F, 'bl', JumpTarget, Offset + 2, Pixel, ModifyZBuffer);
            end;

            if Bits[Offset + 3] then begin
                GenerateJumpTarget(F, JumpTarget);
                if not Bits[Offset + 2] then
                    WriteLn(F, '    shr ebx, 16');
                GeneratePixelCode(F, 'bh', JumpTarget, Offset + 3, Pixel, ModifyZBuffer);
            end;
        end
        { Only bit 2 and 3 are set => load high word into bx }
        else if Bits[Offset + 2] and Bits[Offset + 3] then begin
            GenerateJumpTarget(F, JumpTarget);
            WriteLn(F, '    mov bx, ', GsDiAt(Offset + 2));
            GeneratePixelCode(F, 'bl', JumpTarget, Offset + 2, Pixel, ModifyZBuffer);

            GenerateJumpTarget(F, JumpTarget);
            GeneratePixelCode(F, 'bh', JumpTarget, Offset + 3, Pixel, ModifyZBuffer);
        end
        { Nothing to optimize... compare directly against bytes at memory location }
        else begin
            for Bit := 0 to 3 do begin
                if Bits[Offset + Bit] then begin
                    GenerateJumpTarget(F, JumpTarget);
                    GeneratePixelCode(F, GsDiAt(Offset + Bit), JumpTarget, Offset + Bit, Pixel, ModifyZBuffer);
                end;
            end;
        end;
    end;

    if Pixel > 0 then begin
        GenerateJumpTarget(F, JumpTarget);
        WriteLn(F, '    add si, ', Pixel);
    end;

    WriteLn(F, '    ret');
    WriteLn(F);
end;

procedure GenerateFile(Filename: string; Prefix: string; ModifyZBuffer: Boolean);
var
    Mask: Byte;
    F: Text;
begin
    Assign(F, Filename);
    Rewrite(F);

    GenerateLookupTable(F, Prefix);
    for Mask := 0 to 255 do begin
        GenerateDrawFunc(F, Prefix, ModifyZBuffer, Mask);
    end;

    Close(F);
end;

begin
    GenerateFile('UNITS\DRAW.ASM', 'Draw', false);
    GenerateFile('UNITS\DRAWZ.ASM', 'DrawZ', true);
end.
