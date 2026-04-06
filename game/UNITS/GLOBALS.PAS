unit Globals;

interface

uses GameMap;

const
     TileWidth = 16;
     TileHeight = 16;

     ScreenWidth = 320;
     ScreenHeight = 240;

     LogicalScreenWidth = ScreenWidth + 2 * TileWidth;
     LogicalScreenHeight = ScreenHeight + 2 * TileHeight;

     PlaneWidth = LogicalScreenWidth div 4;

     NumPages = 2;
     PageSize = PlaneWidth * LogicalScreenHeight;
     PageOffset: array[0..NumPages-1] of Word = (0, PageSize);

     ScreenOffset = (TileHeight * PlaneWidth) + (TileWidth div 4);

var
   Map: TGameMap;

implementation

end.