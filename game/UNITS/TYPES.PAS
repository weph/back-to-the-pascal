unit Types;

interface

uses Image;

type
    TDirection = (N, NE, E, SE, S, SW, W, NW);

    TCoordinate = record
        X, Y: Integer;
    end;

    TDirtyRect = object
        X, Y: Word;
        Image: PImage;
    end;

implementation

end.