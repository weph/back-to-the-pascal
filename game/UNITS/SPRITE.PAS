unit Sprite;

interface

uses Types;

type
    PSprite = ^TSprite;
    TSprite = object
        X, Y, Z: Word;
        Width, Height: Byte;

        constructor Init(_X, _Y, _Z: Word; _Width, _Height: Byte);
        procedure Update(Frame: LongInt); virtual;
        procedure Draw(Page: Byte); virtual;
    end;

implementation

constructor TSprite.Init(_X, _Y, _Z: Word; _Width, _Height: Byte);
begin
     X := _X;
     Y := _Y;
     Z := _Z;

     Width := _Width;
     Height := _Height;
end;

procedure TSprite.Update(Frame: LongInt);
begin
     Halt(1);
end;

procedure TSprite.Draw(Page: Byte);
begin
     Halt(1);
end;

end.