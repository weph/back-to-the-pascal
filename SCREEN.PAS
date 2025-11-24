unit Screen;


interface

type
    VideoBuffer = Array[0..63999] of Byte;

type
    PCanvas = ^Canvas;
    Canvas = object
        private
            Memory: Pointer;
            Pointers: Array[0..1000] of Pointer;

        public
            CanvasWidth, CanvasHeight: Word;

            constructor New(TheWidth, TheHeight: Word);
            constructor Using(TheMemory: Pointer; TheWidth, TheHeight: Word);
            destructor Destroy; virtual;
            procedure Fill(Color: Byte); virtual;
            procedure PutPixel(X, Y: Word; Color: Byte); virtual;
            procedure Draw(X, Y, Width, Height: Word; Data: PChar); virtual;
            procedure DrawAlpha(X, Y, Width, Height: Word; Data: PChar); virtual;
            procedure CopyTo(Target: PCanvas); virtual;
            procedure CopyAreaTo(SrcX, SrcY, SrcWidth, SrcHeight: Word; Target: PCanvas; DstX, DstY: Word); virtual;
            procedure Update; virtual;
    end;

    PBuffer = ^Buffer;
    Buffer = object(Canvas)
        private
            NumberOfBlocks: Byte;
            MemBlocks: Array[Byte] of Pointer;

        public
            constructor Init(Width, Height: Word);
            destructor Destroy; virtual;
    end;

    PMode13 = ^Mode13;
    Mode13 = object(Canvas)
        public
            constructor Init;
            destructor Destroy; virtual;
    end;

    PBufferedCanvas = ^BufferedCanvas;
    BufferedCanvas = object(Canvas)
        private
            Screen: PCanvas;

        public
            constructor Init(TheScreen: PCanvas);
            procedure Update; virtual;
    end;

    function VGA: PCanvas;
    function DoubleBufferedVGA: PBufferedCanvas;
    function InMemory(Width, Height: LongInt): PCanvas;



implementation

uses Map;

const
     MemoryBlockSize = 64000;
     MaxBlockSize = 64000;

procedure Move(var Src, Dst; Size: Word);
var
   SrcSeg, SrcOfs, DstSeg, DstOfs, Count: Word;
begin
     asm
        push ds
        lds si, Src
        les di, Dst
        mov cx, Size
        mov ax, cx
        cld
        shr cx, 2
        db 66h
        rep movsw
        mov cl, al
        and cl, 3
        rep movsb
        pop ds
     end;
end;


function VGA;
begin
     VGA := New(PMode13, Init);
end;

function DoubleBufferedVGA;
begin
     DoubleBufferedVGA := New(PBufferedCanvas, Init(VGA));
end;

function InMemory;
var
   SmallCanvas: ^Canvas;
   BigCanvas: ^Buffer;
begin
     if Width * Height > MaxBlockSize then
         InMemory := New(PBuffer, Init(Width, Height))
     else
         InMemory := New(PCanvas, New(Width, Height));
end;

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

constructor Canvas.New;
var
   MemBlock: Pointer;
   Y: Word;
   P1, P2: Pointer;
begin
     GetMem(MemBlock, TheWidth * TheHeight);

     Memory := MemBlock;
     CanvasWidth := TheWidth;
     CanvasHeight := TheHeight;

     for Y := 0 to CanvasHeight - 1 do
         Pointers[Y] := Ptr(Seg(Memory^), Ofs(Memory^) + Y * CanvasWidth);
end;

constructor Canvas.Using;
var
   Y: Word;
begin
     Memory := TheMemory;
     CanvasWidth := TheWidth;
     CanvasHeight := TheHeight;

     if Memory <> Nil then
          for Y := 0 to CanvasHeight - 1 do
              Pointers[Y] := Ptr(Seg(Memory^), Ofs(Memory^) + Y * CanvasWidth);
end;

destructor Canvas.Destroy;
begin
     if Memory <> nil then
        FreeMem(Memory, CanvasWidth * CanvasHeight);
end;

procedure Canvas.PutPixel;
var
   Dst: Pointer;
begin
     if (X < 0) or (Y < 0) or (X >= CanvasWidth) or (Y >= CanvasHeight) then
        Exit;

     Mem[Seg(Pointers[Y]^):Ofs(Pointers[Y]^) + X] := Color;
end;

procedure Canvas.Fill;
var
   Y: Word;
   Src, Dst: Pointer;
begin
     GetMem(Src, CanvasWidth);
     FillChar(Src^, CanvasWidth, Color);

     for Y := 0 to CanvasHeight - 1 do
         Move(Src^, Pointers[Y]^, CanvasWidth);

     FreeMem(Src, CanvasWidth);
end;

procedure Canvas.Draw;
var
   Ty, SrcSeg, SrcOfs: Word;
   Dst: Pointer;
   SrcRow, DstRow: Pointer;
begin
     SrcSeg := Seg(Data^);
     SrcOfs := Ofs(Data^);

     for Ty := 0 to Height - 1 do
     begin
          SrcRow := Ptr(SrcSeg, SrcOfs + Ty * Width);
          Dst := Pointers[Y + Ty];
          DstRow := Ptr(Seg(Dst^), Ofs(Dst^) + X);

          Move(SrcRow^, DstRow^, Width);
     end;
end;


procedure Canvas.DrawAlpha;
var
   Tx, Ty, Color: Byte;
   Sx, Sy: Word;
begin
     for Ty := 0 to Height - 1 do
         for Tx := 0 to Width - 1 do
         begin
             Sx := X + Tx;
             Sy := Y + Ty;
             Color := Byte(Ptr(Seg(Data^), Ofs(Data^) + Ty * Width + Tx)^);

             if (Color <> 0) and (Sx >= 0) and (Sx < CanvasWidth) and (Sy >= 0) and (Sy < CanvasHeight) then
                PutPixel(Sx, Sy, Color);
         end;
end;

procedure Canvas.CopyTo;
begin
     Move(Pointers[0]^, Target^.Pointers[0]^, CanvasWidth * CanvasHeight);
end;

procedure Canvas.CopyAreaTo;
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
   Src, Dst: Pointer;
   SrcSeg, SrcOfs, DstSeg, DstOfs: Word;
begin
     for Ty := 0 to SrcHeight - 1 do
     begin
          Src := Pointers[SrcY + Ty];
          Dst := Target^.Pointers[DstY + Ty];

          Video := Ptr(Seg(Src^), Ofs(Src^) + SrcX);
          Row := Ptr(Seg(Dst^), Ofs(Dst^) + DstX);

          Move(Video^, Row^, SrcWidth);
     end;
end;

procedure Canvas.Update;
begin
end;

constructor Mode13.Init;
var
   Video: Array[0..63999] of Byte absolute $a000:$0000;
begin
     inherited Using(@Video, 320, 200);

     SetVideoMode($13);
end;

destructor Mode13.Destroy;
begin

     SetVideoMode(3);
end;

constructor Buffer.Init;
var
   i: Byte;
   RowsPerBlock: Word;
   RowsCovered: Word;
   CurrentBlock: Byte;
   RowsInBlock: Word;
   Y: Word;
begin
     inherited Using(nil, Width, Height);

     RowsPerBlock := MaxBlockSize div Width;
     if RowsPerBlock > Height then
        RowsPerBlock := Height;

     CurrentBlock := 0;
     RowsCovered := 0;
     Y := 0;
     while Y < Height do
     begin
          GetMem(MemBlocks[CurrentBlock], RowsPerBlock * Width);

          for i := 0 to RowsPerBlock - 1 do
          begin
               Pointers[Y] := Ptr(
                   Seg(MemBlocks[CurrentBlock]^),
                   Ofs(MemBlocks[CurrentBlock]^) + i * Width
               );

               Inc(Y);
          end;

          Inc(CurrentBlock);
          Inc(RowsCovered, RowsPerBlock);
     end;

     NumberOfBlocks := CurrentBlock - 1;
end;

destructor Buffer.Destroy;
var
   i: Byte;
   RowsPerBlock: Word;
begin
     RowsPerBlock := MaxBlockSize div CanvasWidth;
     for i := 0 to NumberOfBlocks do
         FreeMem(MemBlocks[i], RowsPerBlock * CanvasWidth);
end;

constructor BufferedCanvas.Init;
begin
     inherited New(TheScreen^.CanvasWidth, TheScreen^.CanvasHeight);

     Screen := TheScreen;
end;

procedure BufferedCanvas.Update;
begin
     WaitForVRetrace;
     Move(Memory^, Screen^.Memory^, 64000);
end;

end.