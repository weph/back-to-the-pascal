unit Screen;


interface

type
    VideoBuffer = Array[0..63999] of Byte;

type
    PCanvas = ^Canvas;
    Canvas = object
        private
            Memory: Pointer;

            function PositionOf(X, Y: Word): Pointer; virtual;

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
            Pointers: Array[0..1000] of Pointer;

            function PositionOf(X, Y: Word): Pointer; virtual;

        public
            constructor Init(Width, Height: Word);
            destructor Destroy; virtual;
    end;

    PMode13 = ^Mode13;
    Mode13 = object(Canvas)
        private
            function PositionOf(X, Y: Word): Pointer; virtual;

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
begin
     GetMem(MemBlock, TheWidth * TheHeight);

     Memory := MemBlock;
     CanvasWidth := TheWidth;
     CanvasHeight := TheHeight;
end;

constructor Canvas.Using;
begin
     Memory := TheMemory;
     CanvasWidth := TheWidth;
     CanvasHeight := TheHeight;
end;

destructor Canvas.Destroy;
begin
     if Memory <> nil then
        FreeMem(Memory, CanvasWidth * CanvasHeight);
end;

procedure Canvas.PutPixel;
begin
     if (X < 0) or (Y < 0) or (X >= CanvasWidth) or (Y >= CanvasHeight) then
        Exit;

     Move(Color, PositionOf(X, Y)^, 1);
end;

procedure Canvas.Fill;
var
   Y: Word;
   Row: Pointer;
begin
     GetMem(Row, CanvasWidth);
     FillChar(Row^, CanvasWidth, Color);

     for Y := 0 to CanvasHeight do
         Move(Row^, PositionOf(0, Y)^, CanvasWidth);

     FreeMem(Row, CanvasWidth);
end;

procedure Canvas.Draw;
var
   Ty, SrcSeg, SrcOfs: Word;
   SrcRow: Pointer;
begin
     SrcSeg := Seg(Data^);
     SrcOfs := Ofs(Data^);

     for Ty := 0 to Height - 1 do
     begin
          SrcRow := Ptr(SrcSeg, SrcOfs + Ty * Width);

          Move(SrcRow^, PositionOf(X, Y + Ty)^, Width);
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
     Move(PositionOf(0, 0)^, Target^.PositionOf(0, 0)^, CanvasWidth * CanvasHeight);
end;

procedure Canvas.CopyAreaTo;
var
   X, Y: Word;
begin
     for Y := 0 to SrcHeight - 1 do
         Target^.Draw(DstX, DstY + Y, SrcWidth, 1, PositionOf(SrcX, SrcY + Y));
end;

function Canvas.PositionOf;
begin
     PositionOf := Ptr(Seg(Memory^), Ofs(Memory^) + Y * CanvasWidth + X);
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

function Mode13.PositionOf;
begin
     PositionOf := Ptr($a000, Y * 320 + X)
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

function Buffer.PositionOf;
var
   P: Pointer;
   YOffset: Byte;
   DstSeg, DstOfs: Word;
begin
     P := Pointers[Y];

     PositionOf := Ptr(Seg(P^), Ofs(P^) + X);
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