unit VGA;


interface

type
    TColor = record
           Red, Green, Blue: Byte;
    end;

procedure SetVideoMode(Mode: Byte);

procedure WaitForVRetrace;

procedure SetColor(Index: Byte; Color: TColor);


implementation

const
     PaletteMask  = $3c6;
     PaletteWrite = $3c8;
     PaletteData  = $3c9;


procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

procedure WaitForVRetrace;
begin
     asm
        mov dx, 03dah
        @wait_end:
        in al, dx
        test al, 8
        jnz @wait_end
        @wait_start:
        in al, dx
        test al, 8
        jz @wait_start
     end;
end;

procedure SetColor;
var
   R, G, B: Byte;
begin
     Port[PaletteMask] := $ff;
     Port[PaletteWrite] := Index;
     Port[PaletteData] := Color.Red shr 2;
     Port[PaletteData] := Color.Green shr 2;
     Port[PaletteData] := Color.Blue shr 2;
end;


end.