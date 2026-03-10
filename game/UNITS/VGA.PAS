unit VGA;


interface

const
     ScIndex = $3c4;
     ScData = $3c5;

     CrtcIndex = $3d4;
     CrtcData = $3d5;

     MiscOutputWrite = $3c2;

type
    TColor = record
           Red, Green, Blue: Byte;
    end;

procedure SetVideoMode(Mode: Byte);

procedure WaitForVRetrace;

procedure SetColor(Index: Byte; Color: TColor);

procedure InitModeX;

procedure SetCrtc(Register, Value: Byte);

procedure SelectPlanes(Planes: Byte);

procedure SetVideoStartAddress(Offset: Word; Pan: Byte);

procedure SetScreenWidth(Width: Word);

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

procedure InitModeX;
var
   VSyncEnd: Byte;
begin
     SetVideoMode($13);

     { Disable chain 4 mode }
     Port[ScIndex] := 4;
     Port[ScData] := 6;

     { sync reset }
     Port[ScIndex] := 0;
     Port[ScData] := 1;

     { 25 mhz clock / 60 hz }
     Port[MiscOutputWrite] := $e3;

     { undo reset }
     Port[ScIndex] := 0;
     Port[ScData] := 3;

     { reprogram CRTC }
     Port[CrtcIndex] := $11;
     VSyncEnd := Port[CrtcData];
     VSyncEnd := VSyncEnd and $7f;
     Port[CrtcData] := VSyncEnd;

     SetCrtc($06, $0d);
     SetCrtc($07, $3e);
     SetCrtc($09, $41);
     SetCrtc($10, $ea);
     SetCrtc($11, $ac);
     SetCrtc($12, $df);
     SetCrtc($14, $00);
     SetCrtc($15, $e7);
     SetCrtc($16, $06);
     SetCrtc($17, $e3);
end;

procedure SetCrtc;
begin
     Port[CrtcIndex] := Register;
     Port[CrtcData] := Value;
end;

procedure SelectPlanes;
begin
     Port[ScIndex] := 2;
     Port[ScData] := Planes;
end;

procedure SetVideoStartAddress;
var
   OffsetLow, OffsetHigh, PanOffset: Byte;
begin
     OffsetLow := Offset and $ff;
     OffsetHigh := Offset shr 8;
     PanOffset := (Pan shl 1) mod 8;

     asm
        mov dx, 03dah
        @wait_end:
        in al, dx
        test al, 8
        jnz @wait_end

        mov dx, CrtcIndex
        mov al, 0dh
        mov ah, OffsetLow
        out dx, ax
        mov al, 0ch
        mov ah, OffsetHigh
        out dx, ax

        mov dx, 03dah
        @wait_start:
        in al, dx
        test al, 8
        jz @wait_start

        mov dx, 3dah
        in al, dx
        mov dx, 3c0h
        in al, dx
        mov cl, al

        mov dx, 3c0h
        mov al, 13h
        out dx, al
        mov al, PanOffset
        out dx, al

        mov al, cl
        out dx, al
     end;
end;

procedure SetScreenWidth;
begin
     SetCrtc($13, Width div 8);
end;

end.