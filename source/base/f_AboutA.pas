{$R about.res}

unit f_AboutA;

interface

uses
  Messages, Classes, Graphics, Forms, f_A;

type
  TFAboutA = class(TFA)
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    protected
      FBackImage: tBitMap;
  end;

implementation

{$R *.dfm}

uses
  Windows,
  cons, c_strings, misc, main;

procedure TFAboutA.FormCreate(Sender: TObject); begin
  inherited;

  Caption:=about_Caption;
  
  if screen_PPI < 120 then FBackImage:=MngProject.MngResource.Bitmap[res_jpeg_About_96]
  else 
    if screen_PPI < 144 then FBackImage:=MngProject.MngResource.Bitmap[res_jpeg_About_120]
    else FBackImage:=MngProject.MngResource.Bitmap[res_jpeg_About_144];
  
  if FBackImage <> nil then begin
    ClientWidth:=FBackImage.Width;
    ClientHeight:=FBackImage.Height;
  end;
end;

procedure TFAboutA.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); begin
  if Key in [vk_Escape, vk_Return] then Close
end;

procedure TFAboutA.FormPaint(Sender: TObject);
var
  i, h, j: integer;
  r      : tRect;
begin
  with Canvas do begin
    StretchDraw(rect(0, 0, ClientWidth, ClientHeight), FBackImage);
    Brush.Style:=bsClear;

//    Font.Assign(Screen.MenuFont);

    Font.Name:=about_FontName;
    Font.Size:=con_FontSize;

    h:=TextHeight(Caption);
    j:=h - 2;

    with MngProject do
      for i:=0 to AboutLog.Count - 1 do begin
        if (integer(AboutLog.Objects[i]) and _logBold) > 0 then Font.Style:=[fsBold]
        else Font.Style:=[];

        if (integer(AboutLog.Objects[i]) and _logLinePrev) > 0 then inc(j, h div 2);

        if length(AboutLog[i]) > 0 then begin
          r:=rect(h, j, ClientWidth - h, MaxInt);
          inc(j, DrawText(Handle, pChar(AboutLog[i]), -1, r, DT_LEFT or DT_WORDBREAK or DT_NOPREFIX));
        end;

        if (integer(AboutLog.Objects[i]) and _logLine) > 0 then inc(j, h div 2);
      end;
  end
end;

end.

