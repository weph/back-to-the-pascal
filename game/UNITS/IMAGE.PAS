unit Image;


interface

type
    PImage = ^TImage;
    TImage = object
        Width, Height: Word;
        MemSize: Word;
        Data: PChar;
        TransparencyEncoded: Boolean;

        constructor Init(IWidth, IHeight: Word; IData: Pointer);
        destructor Destroy;
        procedure Encode;
        procedure TileEncode;
        procedure TransparencyEncode;
    end;

implementation

uses FMem;

constructor TImage.Init;
begin
     Width := IWidth;
     Height := IHeight;
     Data := IData;
     MemSize := Width * Height;
     TransparencyEncoded := false;
end;

destructor TImage.Destroy;
begin
     FreeMem(Data, MemSize);
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

     TileEncode;
end;

procedure TImage.TileEncode;
var
   i, Pos, CurrentLength: Word;
   Plane, X, Y, PrevY: Word;
   TempSize: Word;
   Temp: PChar;
   Result: PImage;
begin
     GetMem(Temp, MemSize);

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
     FreeMem(Temp, MemSize);
end;

procedure TImage.TransparencyEncode;
var
   Transparent: Boolean;
   i, Pos, CurrentLength: Word;
   Plane: Byte;
   TempSize: Word;
   Temp: PChar;
begin
    TempSize := Width * Height * 4;
    GetMem(Temp, TempSize);

    Pos := 0;

    for Plane := 0 to 3 do begin
        i := Plane;
        Transparent := false;
        CurrentLength := 0;

        while i < Width * Height do begin
            if (i >= Width) and ((i - Plane) mod Width = 0) then begin
                if not Transparent then begin
                    Temp[Pos] := Chr(CurrentLength);
                    Inc(Pos, CurrentLength + 1);
                end;

                Temp[Pos] := Chr(0);
                Temp[Pos + 1] := Chr(0);
                Inc(Pos, 2);

                Transparent := false;
                CurrentLength := 0;
            end;

            if Transparent = (Ord(Data[i]) = 0) then begin
                Inc(CurrentLength);
            end else begin
                if Transparent then begin
                    Temp[Pos] := Chr(0);
                    Temp[Pos + 1] := Chr(CurrentLength);
                    Inc(Pos, 2);
                end else if CurrentLength > 0 then begin
                    Temp[Pos] := Chr(CurrentLength);
                    Inc(Pos, CurrentLength + 1);
                end;

                CurrentLength := 1;
                Transparent := not Transparent;
            end;

            if not Transparent then begin
                Temp[Pos + CurrentLength] := Data[i];
            end;

            Inc(i, 4);
        end;

        if Transparent then begin
            Temp[Pos] := Chr(0);
            Temp[Pos + 1] := Chr(0);
            Inc(Pos, 2);
        end else begin
            Temp[Pos] := Chr(CurrentLength);
            Inc(Pos, CurrentLength + 1);
            Temp[Pos] := Chr(0);
            Temp[Pos + 1] := Chr(0);
            Inc(Pos, 2);

        end;
    end;

    FreeMem(Data, MemSize);

    MemSize := Pos;

    GetMem(Data, MemSize);
    FastMove(Temp^, Data^, MemSize);
    TransparencyEncoded := true;

    FreeMem(Temp, TempSize);
end;

end.