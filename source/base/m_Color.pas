unit m_Color;

interface

uses
  Graphics, Classes,
  rxVclUtils,
  pc,
  iwclasses;

type
  tDefaultMainColors = array[0..15] of tColor;

const
  DefaultMainColors: tDefaultMainColors =
    ($005050FF, $0040F040, $00E05050, $008CE6F0,
     $00E000B6, $00FFBA90, clGreen,   $002266A0,
     clYellow,  $0000008B, $00C0AAFF, $00008CF0,
     $008FBC8F, $00A00060, clGray,    clWhite);

  DefaultMainColors2: tDefaultMainColors =
    ($0000008B, $002266A0, clGreen,   $00A00060,
     $00E05050, $00008CF0, $00FFBA90, $005050FF,
     $0040F040, $00C0AAFF, clGray,    $00E050B0,
     $008CE6F0, $00E000B6, clYellow,  clWhite);

type
  tMngColor = class(tMngA)
    protected
      FMainColors : array of tColor;
      FColors     : tList;
      FVarsName   : string;
      FVarsVrfFunc: tVrfFuncObj;

      function GetCount: integer;
      function GetColor(AIndex: integer): tColor;
      procedure SetMainColorVars(AIndex: integer; AColor: tColor);
      procedure AddToVariablesConfig(AList: tStringList);
      procedure ListMainColors;
      function ColorToStr(AColor: tColor): string;

    public
      constructor Create;
      destructor Destroy; override;

      procedure InitMainColors(AMainColorCount: integer; AVarsName, AVarsNameList: string; AVarsVrfFunc: tVrfFuncObj);
      procedure InitDefaultMainColors(AVarsName, AVarsNameList: string; AVarsVrfFunc: tVrfFuncObj);
      procedure SetMainColor(AIndex: integer; AColor: tColor);
      function AddColor(var AColor: tColor): integer;

      property Count: integer read GetCount;
      property Color[Index: integer]: tColor read GetColor; default;
  end;

implementation

uses
  SysUtils,
  rxStrUtils,
  vars,
  misc, c_strings;

constructor tMngColor.Create; begin
  inherited;
  FColors:=tList.Create;
  SetLength(FMainColors, 0);
end;

destructor tMngColor.Destroy; begin
  FColors.Free;
  inherited
end;

function tMngColor.GetCount; begin
  Result:=length(FMainColors) + FColors.Count;
end;

function tMngColor.GetColor; begin
  if AIndex < length(FMainColors) then Result:=FMainColors[AIndex]
  else Result:=tColor(FColors[AIndex - length(FMainColors)]^)
end;

procedure tMngColor.InitMainColors; begin
  FVarsName:=AVarsName;
  FVarsVrfFunc:=AVarsVrfFunc;

  with Variables do begin
    RegistryFunction(FVarsName, @tMngColor.SetMainColorVars, self, vtVoid, [vtInteger, vtColor]);
    RegistryFunction(AVarsNameList, @tMngColor.ListMainColors, self, vtVoid, []);
    SetOnSaveConfig(AddToVariablesConfig);
  end;

  SetLength(FMainColors, AMainColorCount);
end;

procedure tMngColor.InitDefaultMainColors;
var i: integer;
begin
  InitMainColors(length(DefaultMainColors), AVarsName, AVarsNameList, AVarsVrfFunc);
  for i:=low(DefaultMainColors) to high(DefaultMainColors) do
    SetMainColor(i, DefaultMainColors[i])
end;

procedure tMngColor.SetMainColorVars; begin
  if (AIndex >= 0) and (AIndex < length(FMainColors)) then begin
    SetMainColor(AIndex, AColor);
    FVarsVrfFunc(nil)
  end
  else
    log_err(Format(log_err_invalidarg, [vn_g_QuadCountChance]))
end;

procedure tMngColor.SetMainColor; begin
  FMainColors[AIndex]:=AColor
end;

function tMngColor.AddColor; begin
  FColors.Add(@AColor);
  Result:=GetCount - 1
end;

function tMngColor.ColorToStr; begin
  Result:=Variables.ConstToStr(ReplaceStr(ColorToString(AColor), '$', '0x'), vtColor)
end;

procedure tMngColor.AddToVariablesConfig;
var i: integer;
begin
  if length(FMainColors) > 0 then
    for i:=0 to length(FMainColors) - 1 do
      AList.Add(Format(FVarsName + cfg_mcolor_func, [i, ColorToStr(FMainColors[i])]))
end;

procedure tMngColor.ListMainColors;
var i: integer;
begin
  if length(FMainColors) = 0 then log(log_color_Empty)
  else
    for i:=0 to length(FMainColors) - 1 do
      log(Format(log_color_List, [i, ColorToStr(FMainColors[i])]))
end;

end.

