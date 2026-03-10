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

procedure PutChar(X, Y: Word; C: Char);

procedure PutString(X, Y: Word; S: String);

procedure InitModeX;

procedure ModeXPutPixel(X, Y: Word; Color: Byte);

procedure ModeXFill(Color: Byte);

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

procedure PutChar;
var
   Cx, Cy, Mask, Color: Byte;
   Chars: array[0..255*8] of byte absolute $f000:$fa6e;
   Vga: array[0..63999] of byte absolute $a000:$0000;
begin
     for Cy := 0 to 7 do
     begin
          Mask := $80;
          for Cx := 0 to 7 do
          begin
               if Chars[Ord(C) * 8 + Cy] and Mask = Mask then
                   Color := 31
               else
                   Color := 0;

               ModeXPutPixel(X + Cx, Y + Cy, Color);

               Mask := Mask shr 1;
          end;
     end;
end;

procedure PutString;
var
   i: Integer;
begin
     for i := 1 to Length(S) do
         PutChar(X + (i - 1) * 8, Y, S[i]);
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

procedure ModeXPutPixel;
var
   Plane: Byte;
   Dx: Word;
begin
     Dx := X div 4;
     Plane := X mod 4;

     SelectPlanes(1 shl Plane);
     Mem[$a000:Y * 96 + Dx] := Color;
end;

procedure ModeXFill;
begin
     SelectPlanes($f);
     FillChar(Mem[$a000:$0000], 65535, Color);
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

procedure SetVideoStartAddressOld;
begin
     {low byte}
     {Port[CrtcIndex] := $0d;
     Port[CrtcData] := Offset and $ff;}

     {high byte}
     {Port[CrtcIndex] := $0c;
     Port[CrtcData] := Offset shr 8;}
end;

procedure SetVideoStartAddress;
var
   OffsetLow, OffsetHigh, PanOffset: Byte;
begin
     OffsetLow := Offset and $ff;
     OffsetHigh := Offset shr 8;
     PanOffset := (Pan shl 1) mod 8;

         {Tmp := Port[$3da];
         Tmp := Port[$3c0];
         Port[$3c0] := $13;
         Port[$3c0] := (X shl 1) mod 8;
         Port[$3c0] := Tmp;}


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