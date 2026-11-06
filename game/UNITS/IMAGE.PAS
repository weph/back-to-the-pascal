unit Image;

interface

type
    PImage = ^TImage;
    TImage = object
    public
        Width, Height: Word;
        MemSize: Word;
        Data: PChar;
        TransparencyEncoded: Boolean;

        constructor Init(IWidth, IHeight: Word; IData: Pointer);
        constructor New(IWidth, IHeight: Word);
        destructor Destroy;
        procedure Fill(Color: Byte);

    private
        procedure Encode;
        procedure OpaqueEncode;
        procedure TransparencyEncode;
    end;

implementation

uses
    FMem,
    Malloc;

constructor TImage.Init;
begin
    Width := IWidth;
    Height := IHeight;
    Data := IData;
    MemSize := Width * Height;
    TransparencyEncoded := false;
    Encode;
end;

constructor TImage.New;
begin
    Width := IWidth;
    Height := IHeight;
    MemSize := Width * Height;
    TransparencyEncoded := false;
    M_Alloc(Data, MemSize);
    Fill(0);
end;

destructor TImage.Destroy;
begin
    M_Free(Data, MemSize);
end;

procedure TImage.Fill(Color: Byte);
begin
    FillChar(Data^, MemSize, Color);
end;

procedure TImage.Encode;
var
    i: Word;
begin
    for i := 0 to MemSize - 1 do begin
        if Ord(Data[i]) = 0 then begin
            TransparencyEncode;
            Exit;
        end;
    end;

    OpaqueEncode;
end;

procedure TImage.OpaqueEncode;
var
    i, Pos: Word;
    Plane: Word;
    Temp: PChar;
begin
    M_Alloc(Temp, MemSize);

    Pos := 0;

    for Plane := 0 to 3 do begin
        i := Plane;

        while i < Width * Height do begin
            Temp[Pos] := PChar(Data)[i];

            Inc(Pos);
            Inc(i, 4);
        end;
    end;

    FastMove(Temp^, Data^, MemSize);
    M_Free(Temp, MemSize);
end;

procedure TImage.TransparencyEncode;
var
    X, Y: Word;
    Pos, CurrentLength: Word;
    Plane: Byte;
    TempSize: Word;
    Temp: PChar;
    Mask: Byte;
    CurrentBit: Byte;
    CurrentValue: Byte;
begin
    TempSize := Width * Height + Height;
    M_Alloc(Temp, TempSize);

    Pos := 0;

    for Plane := 0 to 3 do begin
        for Y := 0 to Height - 1 do begin
            Mask := 0;
            CurrentLength := 0;

            for X := 0 to (Width shr 2) - 1 do begin
                CurrentBit := 7 - X;
                CurrentValue := Ord(Data[Y * Width + (X * 4) + Plane]);

                if CurrentValue <> 0 then begin
                    Mask := Mask or (1 shl CurrentBit);
                    Inc(CurrentLength);
                    Temp[Pos + CurrentLength] := Chr(CurrentValue);
                end;
            end;

            Temp[Pos] := Chr(Mask);
            Inc(Pos, CurrentLength + 1);
        end;
    end;

    M_Free(Data, MemSize);

    MemSize := Pos;

    M_Alloc(Data, MemSize);
    FastMove(Temp^, Data^, MemSize);
    TransparencyEncoded := true;

    M_Free(Temp, TempSize);
end;

end.
