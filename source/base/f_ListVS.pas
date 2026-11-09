unit f_ListVS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, f_ListA, StdCtrls, Buttons, Grids;

type
  TFListVS = class(TFListA)
    ButtonNone: TBitBtn;
    procedure ButtonOkClick(Sender: TObject);
    procedure GridClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    protected
      FFiles,
      FSaveVars: tStringList;
      FPath    : string;
      FPrevRow : integer;
      FEasy    : boolean;

      procedure RestoreConfig;
      procedure MakeSelf; override;
      function AddButtons: integer; override;

    public
      function LoadConfigs(APath: string): boolean;

      property Path: string read FPath;
      property Files: tStringList read FFiles;
      property Easy: boolean read FEasy write FEasy; // false - gameplay, true - appearance
  end;


implementation

{$R *.dfm}

uses Math, RxStrUtils,
     vars, pc, i_str,
     c_strings, main, misc, m_ProjectA;

procedure TFListVS.ButtonOkClick(Sender: TObject); begin
  if FEasy then
    if Grid.Row > 0 then MngProject.LoadTemplate(FFiles[Grid.Row - 1], FPath);

  inherited;
end;

procedure TFListVS.FormCreate(Sender: TObject); begin
  inherited;

  FEasy:=true;
  FPrevRow:=0;
  FFiles:=tStringList.Create;
  FSaveVars:=tStringList.Create;
  Variables.GetConfigsStrings(FSaveVars);
end;

procedure TFListVS.FormDestroy(Sender: TObject); begin
  if ModalResult = mrCancel then RestoreConfig;

  FFiles.Free;
  FSaveVars.Free;

  inherited;
end;

procedure TFListVS.GridClick(Sender: TObject); begin
  if not FEasy then
    if FPrevRow <> Grid.Row then begin
      FPrevRow:=Grid.Row;

      if FPrevRow = 0 then RestoreConfig
      else MngProject.LoadTemplate(FFiles[FPrevRow - 1], FPath);

      BringToFront;
    end
end;

procedure TFListVS.RestoreConfig; begin
  MngProject.Exec(FSaveVars);
end;

function TFListVS.AddButtons; begin
  ButtonNone.Font.Assign(ButtonOk.Font);
  ButtonNone.Caption:=list_appearance_button_Cfg;
  ButtonNone.Width:=ButtonWidth([ButtonNone.Caption]);
  ButtonNone.Height:=ButtonOk.Height;

  Result:=ButtonNone.Width + FSpace;
end;

procedure TFListVS.MakeSelf;
var mf: tForm;
begin
  inherited;

  ButtonNone.Left:=ClientWidth - FSpace - ButtonNone.Width;
  ButtonNone.Top:=ButtonOk.Top;

  mf:=MngProject.MainForm;

  if not FEasy then begin
    if mf.Left - Screen.WorkAreaLeft > Screen.WorkAreaLeft + Screen.WorkAreaWidth - mf.Left - mf.Width then
      Left:=Max(Screen.WorkAreaLeft, mf.Left - Width) // слева от формы
    else
      Left:=Min(mf.Left + mf.Width, Screen.WorkAreaLeft + Screen.WorkAreaWidth - Width); // справа от формы

    Top:=Min(mf.Top, Screen.WorkAreaTop + Screen.WorkAreaHeight - Height);
  end;
end;

function TFListVS.LoadConfigs;

  function FillSList(AConfig: tStringList; var AList: tStringList; ALanguage: string): boolean;
  var
    i      : integer;
    s, slng: string;
  begin
    AList.Clear;
    i:=0;
    Result:=false;

    while (i < AConfig.Count) do begin
      s:=DelBSpace(AConfig[i]);
      
      if (Copy(s, 1, 2) = '//') then begin
        s:=DelRSpace(Copy(AConfig[i], 3, MaxInt));

        if (length(s) > 0) then begin
          if s[1] <> list_LngFormat[1] then AList.Add(s)
          else begin
            slng:=Format(list_LngFormat, [ALanguage]);
            if CompareStrBegin(s, slng) then begin
              Result:=true;
              AList.Add(DelRSpace(Copy(s, length(slng) + 1, MaxInt)))
            end;
          end;
        end;
      end;

      inc(i)
    end;
  end;

var
  i, j: integer;
  n, sl, slRems: tStringList;
begin
  FPath:=APath;
  sl:=tStringList.Create;
  slRems:=tStringList.Create;

  Result:=GetFilesMask(FPath + '*' + fn_Ext_Cfg, FFiles);
  FFiles.Sort;

  if not Result then log_err(Format(log_fs_err_ScanDir, [FPath]))
  else begin
    log(Format(log_fs_inf_ScanDir, [FPath]));
    if not FEasy then Texts.New.Add(list_appearance_current)
    else Texts.New.Add(list_gameplay_current);

    i:=0;
    while Result and (i < FFiles.Count) do begin
      n:=Texts.New;
      sl.Clear;
      try
        sl.LoadFromFile(FPath + FFiles[i]);
      except
        Result:=false;
        log_err(Format(ms_var_ErrorLoad, [FPath + FFiles[i]]));
      end;

      if Result then begin
        if not FillSList(sl, slRems, MngProject.Language) then FillSList(sl, slRems, c_English);
        for j:=0 to slRems.Count - 1 do
          if j = 0 then n.Add('[' + FFiles[i] + '] ' + list_Metka + slRems[j])
          else n.Add(slRems[j]);
      end;

      inc(i);
    end;
  end;

  slRems.Free;
  sl.Free
end;

end.

