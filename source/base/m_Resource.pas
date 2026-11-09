unit m_Resource;

interface

uses
  Windows, Classes, Graphics, Jpeg,
  iwclasses;

type
  tMngResource = class(tMngA)
    protected
      FList: tStringList;

      function _GetBitMap(AName: string): tBitmap;
      function _GetIcon(AName: string): tIcon;

    public
      constructor Create;
      destructor Destroy; override;

      function LoadJpeg(AResourceName: string): tJpegImage;

      property Bitmap[AName: string]: tBitmap read _GetBitmap; default;
      property Icon[AName: string]: tIcon read _GetIcon;
  end;

implementation

uses
  i_str, c_strings;
  
constructor tMngResource.Create; begin
  inherited;

  FList:=tStringList.Create;
  Flist.Sorted:=true;
end;

destructor tMngResource.Destroy;
var i: integer;
begin
  for i:=0 to FList.Count - 1 do begin
    if FList.Objects[i] is tBitmap then DeleteObject(tBitmap(FList.Objects[i]).Handle)
    else
      if FList.Objects[i] is tIcon then DeleteObject(tIcon(FList.Objects[i]).Handle);

    FList.Objects[i].Free
  end;

  FList.Free;

  inherited
end;

function tMngResource._GetBitMap;
var
  i : integer;
  bm: tBitmap;
  j : tJpegImage;
  h : tHandle;
begin
  if FList.Find(AName, i) then Result:=tBitmap(FList.Objects[i])
  else begin

    if CompareStrBegin(AName, res_jpeg) then begin
      j:=LoadJpeg(AName);
      bm:=tBitmap.Create;
      bm.Assign(j);
      j.Free
    end
    else begin
      h:=LoadBitmap(hInstance, pChar(AName));
      if h = 0 then bm:=nil
      else begin
        bm:=tBitmap.Create;
        bm.Handle:=h;
      end
    end;

    FList.AddObject(AName, bm);
    Result:=bm
  end
end;

function tMngResource._GetIcon;
var
  i : integer;
  ic: tIcon;
  h : tHandle;                                                                                 
begin
  if FList.Find(AName, i) then Result:=tIcon(FList.Objects[i])
  else begin
    h:=LoadIcon(hInstance, pChar(AName));

    if h = 0 then ic:=nil
    else begin
      ic:=tIcon.Create;
      ic.Handle:=h;
    end;

    FList.AddObject(AName, ic);
    Result:=ic
  end
end;

function tMngResource.LoadJpeg;
var rs: tResourceStream;
begin
  Result:=nil;
  try
    rs:=tResourceStream.Create(0, AResourceName, RT_RCDATA);
  except
    rs:=nil;
  end;
  if rs <> nil then
    try
      Result:=tJPEGImage.Create;
      Result.LoadFromStream(rs);
    finally
      rs.Free;
    end
end;

end.

