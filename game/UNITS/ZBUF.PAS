{$L ZBUF.OBJ}
unit ZBuf;

interface

uses
    Globals;

procedure ZBuf_Init;

procedure ZBuf_Destroy;

procedure ZBuf_Draw(Page: Byte);

procedure ZBuf_Clear;

procedure ZBuf_ClearFirstCol(Page: Byte);

procedure ZBuf_ClearLastCol(Page: Byte);

procedure ZBuf_ClearFirstRow(Page: Byte);

procedure ZBuf_ClearLastRow(Page: Byte);

implementation

function ZBuf_Allocate: Boolean; far; external;

procedure ZBuf_Init;
begin
    if not ZBuf_Allocate then
        RunError(203);
    ZBuf_Clear;
end;

procedure ZBuf_Destroy; external;

procedure ZBuf_Draw; external;

procedure ZBuf_Clear; external;

procedure ZBuf_ClearFirstCol; external;

procedure ZBuf_ClearLastCol; external;

procedure ZBuf_ClearFirstRow; external;

procedure ZBuf_ClearLastRow; external;

end.
