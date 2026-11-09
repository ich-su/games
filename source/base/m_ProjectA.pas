{$R console.res}
{$R icons.res}
{$R manifest.res}
{$I defines.inc}

unit m_ProjectA;

interface

uses
  Messages, Menus, SysUtils, Controls, Classes, Dialogs, IniFiles,
  spTrayIcon,
  vars, i_classes,
  c_strings, t_fMain, t_mGame, iwclasses, m_Control, m_Resource;

const
  iwg_Version        : string = {$I ..\_version\engine.};

  mfb_Single         = 0;
  mfb_SingleNoButton = 1;
  mfb_ToolEasy       = 2;
  mfb_Tool           = 3;
  mfb_None           = 4;

  mfb_Min            = mfb_Single;
  mfb_Max            = mfb_None;

  mf_Border          : integer = mfb_ToolEasy;
  tray_AlwaysIcon    : boolean = false;
  exception_Show     : boolean = true;
  prj_templates_Mode : boolean = true;

var
  fn_QuickSave,
  fn_Save            : string;
  pth_SaveGames      : string = c_pth_SaveGames;
  pth_ViewStyles     : string = c_pth_ViewStyles;
  pth_Gameplay       : string = c_pth_Gameplay;
  pth_Help           : string = c_pth_Help;

  prj_RealExeNameWithOutExt: string;

  prj_temp           : array[0..4] of string;

type
  tMngProjectA = class(tMngA)
    protected
      FMainForm       : tFMain;
      FMngControl     : tMngControl;
      FMngGame        : tMngGame;
      FMngResource    : tMngResource;
      FTray           : tspTrayIcon;
      FTrayMenu       : tPopupMenu;
      FAboutLogEnabled: boolean;
      FAboutLog,
      FLanguages      : tStringList;
      FLanguage       : string;
      FIniLng         : tIniFile;
      FInfoCache      : tDoubleStringList;

      procedure InitBasic; virtual;
      procedure InitVariables; virtual;
      procedure InitApplication; virtual;
      procedure InitConsole; virtual;
      procedure InitManagers; virtual;
      procedure InitMainForm; virtual;
      procedure InitTray; virtual;
      procedure LoadConfigs; virtual;
      procedure InitAfter0; virtual;
      procedure InitAfter; virtual;

      procedure DoneBefore; virtual;
      procedure SaveConfigs; virtual;
      procedure DoneTray; virtual;
      procedure DoneMainForm; virtual;
      procedure DoneManagers; virtual;
      procedure DoneConsole; virtual;
      procedure DoneApplication; virtual;
      procedure DoneVariables; virtual;
      procedure DoneBasic; virtual;

      procedure tolog_MainInfo; virtual;
      procedure RegistryMainVars; virtual;
      function VrfMainVars(PtrValue: pointer): boolean; virtual;

      procedure SetConsoleImage; virtual;

      procedure OnGlobalCompilerErrFunc(AError: string);
      procedure OnAppActivate(ASender: TObject);
      procedure OnAppException(ASender: tObject; AException: exception);
      procedure OnTrayDblClick(ASender: tObject);
      procedure OnTrayClick(ASender: tObject; AButton: tMouseButton);
      procedure OnTrayBeforePopup(Sender: tObject);

      procedure tray_OnQuit(ASender: tObject);
      procedure tray_OnShowHide(ASender: tObject);

      function DialogExecute(ADialog: tOpenDialog; var AFileName: string; AFilter, AInitialDir, AExt: string): boolean;
      function VerifyFileName(var AFileName: string; var ANextDir: string): boolean;

      procedure Save(AFileName: string; ANextDir: string = '.'; AEx: boolean = false);
      procedure Load(AFileName: string; ANextDir: string = '.');
      procedure About;

      procedure SaveDef(AFileName: string);
      procedure LoadDef(AFileName: string);
      procedure SaveEx(AFileName: string);

      procedure Help;

      function ShowTemplatesNew(ACaption, ATitle, APath: string; AEasy: boolean): tModalResult;
      procedure ViewStyles(AFileName: string);
      procedure Gameplay(AFileName: string);
      function ViewStylesNew: tModalResult;
      function GameplayNew: tModalResult;
      procedure ConsoleOpenCfg(Sender: tObject);

      procedure iLog(AFileName: string);

      function RoamingPath: string;
      function RoamingPathProject: string;

      function LoadCfl(AFileName: string; var AResult: string): boolean;
      function SaveCfl(AFileName, AData: string): boolean;

      function SetWorkPath: boolean;
      function SetLanguage: boolean;

      function DropCfl(AFileName: string): boolean;
      function DropLocation: boolean;
      function DropLanguage: boolean;

      function GetLanguages: boolean;
      function FindLanguage(ALanguage: string): integer;
      function LoadLanguageFile: boolean;
      class function ParseLanguage(AIni: tIniFile): boolean; virtual;
      function LanguageToControls: boolean;
      procedure DoneLanguage;

      function math_Min(V1, V2: integer): integer;
      function math_Max(V1, V2: integer): integer;

    public
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; override;

      procedure BringToFront;
      procedure BeforeTerminate; virtual;

      procedure prjQuit;
      procedure prjMinimize;
      procedure prjHideToTray;

      function Init: boolean;
      procedure Done;
      function Run: boolean; virtual;

      procedure Exec(AConfig: tStringList); overload;
      procedure Exec(AFileName: string); overload;
      procedure LoadTemplate(AFileName, ADir: string);

      function GetLngString(AString: string): string;
      property Language: string read FLanguage;

      property MainForm: tFMain read FMainForm;
      property AboutLogEnabled: boolean read FAboutLogEnabled;
      property AboutLog: tStringList read FAboutLog;

      property MngControl: tMngControl read FMngControl;
      property MngResource: tMngResource read FMngResource;
      property MngGame: tMngGame read FMngGame;
  end;

implementation

uses
  Windows, Math, ShlObj, Forms, Jpeg,
  RxStrUtils,
  i_str, i_sys,
  cons, pc,
  misc, c_project, m_GameA, t_fAbout, f_ListA, f_ListVS;

var
  prj_NameR: string;


function tMngProjectA.Run; begin
  Result:=true;
  Application.Run;
end;

function tMngProjectA.DropCfl;
var
  fn: string;
  b : boolean;
begin
  b:=Console.Visible;
  Result:=(not b) or (MessageBox(Console.Handle, pChar(msg_AreYouShure), pChar(msg_Confirm), MB_YESNO) = IDYES);

  if Result then begin
    fn:=RoamingPath + AFileName;

    if FileExists(fn) then begin
      try
        Result:=DeleteFile(pChar(fn));
      except
        Result:=false
      end;

      if Result then log(Format(log_fs_DeleteFile, [fn]))
      else log(Format(log_fs_err_DeleteFile, [fn]));
    end;
  end;

  if b then Console.BringToFront;
end;

function tMngProjectA.DropLocation; begin
  Result:=DropCfl(fn_Location);
end;

function tMngProjectA.DropLanguage; begin
  Result:=DropCfl(fn_Language);
end;

function tMngProjectA.LoadCfl;
var
  fn: string;
  sl: tStringList;
begin
  Result:=true;
  AResult:='';

  fn:=RoamingPath + AFileName;
  if FileExists(fn) then begin
    sl:=tStringList.Create;
    try
      sl.LoadFromFile(fn);
      if sl.Count > 0 then AResult:=DelRSpace(sl[0]);
      log(Format(ms_var_Load, [fn]))
    except
      log_err(Format(ms_var_ErrorLoad, [fn]));
      Result:=false
    end;
    sl.Free;
  end;
end;

function tMngProjectA.SaveCfl;
var
  sl: tStringList;
  fn: string;
begin
  if not DirectoryExists(RoamingPath) then Result:=ForceDirectories(RoamingPath)
  else Result:=true;

  if Result then begin
    sl:=tStringList.Create;
    sl.Add(AData);
    try
      fn:=RoamingPath + AFileName;
      sl.SaveToFile(fn);
      log(Format(ms_var_Save, [fn]))
    except
      fn:=Format(ms_var_ErrorSave, [fn]);
      log_err(fn);
      MessageDlg(fn, mtError, [mbCancel], 0);
      Result:=false;
    end;
    sl.Free
  end
end;

function tMngProjectA.LanguageToControls;
var
  sl: tStringList;
  s : string;
  i: integer;
begin
  Result:=true;
  if FIniLng <> nil then begin
    sl:=tStringList.Create;
    try
      MngControl.iLog(sl);

      for i:=0 to sl.Count - 1 do begin
        s:=FIniLng.ReadString(ini_controls, sl[i], '');
        if (length(s) > 0) and not CompareStrFlags(sl[i], s) then
          MngControl.RegistryAlias(s, sl[i]);
      end;

    except
      Result:=false;
    end;
    sl.Free
  end;
end;

function tMngProjectA.GetLngString;
var
  i: integer;
  s, s_end, s_f: string;
begin
  Result:=AString;

  if show_Translate and (FIniLng <> nil) then begin
    s:=DelSpace(AString);

    if length(s) > 0 then begin
      if s[length(s)] = ':' then begin // тут можно проверку на разные символы замутить
        s_end:=s[length(s)];
        SetLength(s, length(s) - 1);
      end
      else s_end:='';

      // кэшируютс€ в том числе и controls!

      if FInfoCache.FindSortedStr(s, i) then
        if length(FInfoCache[i].String2) > 0 then Result:=FInfoCache[i].String2 + s_end
        else // ничего - кэш отсутстви€ перевода строки

      else 
        try
          s_f:=MngControl.ControlToAlias(s); // control
          if length(s_f) = 0 then s_f:=FIniLng.ReadString(ini_game, s, ''); // ini

          s_f:=lowerstr(s_f);
          FInfoCache.AddSorted(tDoubleString.Create(s, s_f));
          if length(s_f) > 0 then Result:=s_f + s_end
        except
        end;
    end;
  end;
end;

procedure tMngProjectA.DoneLanguage; begin
  if FIniLng <> nil then FIniLng.Free;
end;

class function tMngProjectA.ParseLanguage;
var i: integer;
begin
  try
    with AIni do begin
      vars.ms_var_Load         := ReadString(ini_main, 'ms_var_Load', ms_var_Load);
      vars.ms_var_ErrorLoad    := ReadString(ini_main, 'ms_var_ErrorLoad', ms_var_ErrorLoad);
      vars.ms_var_Save         := ReadString(ini_main, 'ms_var_Save', ms_var_Save);
      vars.ms_var_ErrorSave    := ReadString(ini_main, 'ms_var_ErrorSave', ms_var_ErrorSave);
      vars.ms_var_InitVariables:= ReadString(ini_main, 'ms_var_InitVariables', ms_var_InitVariables);
      vars.ms_var_NoVars       := ReadString(ini_main, 'ms_var_NoVars', ms_var_NoVars);
      vars.ms_var_Param        := ReadString(ini_main, 'ms_var_Param', ms_var_Param);

      cons.con_Name            := ReadString(ini_main, 'con_Name', cons.con_Name);
      cons.con_ExtHintInc      := ReadString(ini_main, 'con_ExtHintInc', cons.con_ExtHintInc);
      cons.con_ExtHintDec      := ReadString(ini_main, 'con_ExtHintDec', cons.con_ExtHintDec);
      cons.con_ExtHintOpenCfg  := ReadString(ini_main, 'con_ExtHintOpenCfg', cons.con_ExtHintOpenCfg);

      for i:=low(pc.Errors) to high(pc.Errors) do
        pc.Errors[i]:=ReplaceStr(ReadString(ini_main, Format('esl_Error%0d', [i]), pc.Errors[i]), '#1', #1);

      log_prj_Exception             := ReadString(ini_main, 'log_prj_Exception', log_prj_Exception);

      log_ctrl_err_InvalidControl   := ReadString(ini_main, 'log_ctrl_err_InvalidControl', log_ctrl_err_InvalidControl);
      log_ctrl_err_InvalidKey       := ReadString(ini_main, 'log_ctrl_err_InvalidKey', log_ctrl_err_InvalidKey);
      log_ctrl_err_CannotAssign     := ReadString(ini_main, 'log_ctrl_err_CannotAssign', log_ctrl_err_CannotAssign);
      log_ctrl_err_CannotDelete     := ReadString(ini_main, 'log_ctrl_err_CannotDelete', log_ctrl_err_CannotDelete);
      log_ctrl_err_InvalidEslString := ReadString(ini_main, 'log_ctrl_err_InvalidEslString', log_ctrl_err_InvalidEslString);
      log_fs_err_DirNotFound        := ReadString(ini_main, 'log_fs_err_DirNotFound', log_fs_err_DirNotFound);
      log_fs_err_ForceDirs          := ReadString(ini_main, 'log_fs_err_ForceDirs', log_fs_err_ForceDirs);
      log_fs_err_FileNotFound       := ReadString(ini_main, 'log_fs_err_FileNotFound', log_fs_err_FileNotFound);
      log_fs_err_ScanDir            := ReadString(ini_main, 'log_fs_err_ScanDir', log_fs_err_ScanDir);
      log_fs_inf_ScanDir            := ReadString(ini_main, 'log_fs_inf_ScanDir', log_fs_inf_ScanDir);
      log_fs_DeleteFile             := ReadString(ini_main, 'log_fs_DeleteFile', log_fs_DeleteFile);
      log_fs_err_DeleteFile         := ReadString(ini_main, 'log_fs_err_DeleteFile', log_fs_err_DeleteFile);

      log_frm_Create                := ReadString(ini_main, 'log_frm_Create', log_frm_Create);
      log_frm_Free                  := ReadString(ini_main, 'log_frm_Free', log_frm_Free);

      log_err_invalidarg            := ReadString(ini_main, 'log_err_invalidarg', log_err_invalidarg);

      log_color_Empty               := ReadString(ini_main, 'log_color_Empty', log_color_Empty);

      menu_tray_Quit                := ReadString(ini_main, 'menu_tray_Quit', menu_tray_Quit);
      menu_tray_Show                := ReadString(ini_main, 'menu_tray_Show', menu_tray_Show);
      menu_tray_Hide                := ReadString(ini_main, 'menu_tray_Hide', menu_tray_Hide);

      list_button_Ok                := ReadString(ini_main, 'list_button_Ok', list_button_Ok);
      list_button_Cancel            := ReadString(ini_main, 'list_button_Cancel', list_button_Cancel);

      list_workpath_Caption         := ReadString(ini_main, 'list_workpath_Caption', list_workpath_Caption);
      list_workpath_Title           := ReadString(ini_main, 'list_workpath_Title', list_workpath_Title);
      list_workpath_1               := ReadString(ini_main, 'list_workpath_1', list_workpath_1);
      list_workpath_2               := ReadString(ini_main, 'list_workpath_2', list_workpath_2);

      list_appearance_Caption       := ReadString(ini_main, 'list_appearance_Caption', list_appearance_Caption);
      list_appearance_Title         := ReadString(ini_main, 'list_appearance_Title', list_appearance_Title);
      list_appearance_current       := ReadString(ini_main, 'list_appearance_current', list_appearance_current);
      list_appearance_button_Cfg    := ReadString(ini_main, 'list_appearance_button_Cfg', list_appearance_button_Cfg);

      list_gameplay_Caption         := ReadString(ini_main, 'list_gameplay_Caption', list_gameplay_Caption);
      list_gameplay_Title           := ReadString(ini_main, 'list_gameplay_Title', list_gameplay_Title);
      list_gameplay_current         := ReadString(ini_main, 'list_gameplay_current', list_gameplay_current);

      msg_AreYouShure               := ReadString(ini_main, 'msg_AreYouShure', msg_AreYouShure);
      msg_Confirm                   := ReadString(ini_main, 'msg_Confirm', msg_Confirm);
    end;

    Result:=tMngGame.ParseLanguage(AIni);
  except
    Result:=false;
  end;
end;

function tMngProjectA.LoadLanguageFile;
var fn: string;
begin
  FIniLng:=nil;
  fn:=var_ExePath + c_pth_Languages + FLanguage + fn_Ext_Lng;

  Result:=FileExists(fn);
  if Result then begin
    FIniLng:=tIniFile.Create(fn);
    try
      Result:=ParseLanguage(FIniLng);
    except
      Result:=false;
    end;
  end;

  if Result then log(Format(ms_var_Load, [fn]))
  else log_err(Format(ms_var_ErrorLoad, [fn]))
end;

function tMngProjectA.GetLanguages;
var
  pth: string;
  i  : integer;
begin
  pth:=var_ExePath + c_pth_Languages;
  Result:=GetFilesMask(pth + '*' + fn_Ext_Lng, FLanguages);

  if not Result then log_err(Format(log_fs_err_ScanDir, [pth]))
  else begin
    log(Format(log_fs_inf_ScanDir, [pth]));

    for i:=0 to Flanguages.Count - 1 do
      FLanguages[i]:=ChangeFileExt(FLanguages[i], '');
  end;
end;

function tMngProjectA.FindLanguage(ALanguage: string): integer;
var i: integer;
begin
  Result:=-1;
  for i:=0 to FLanguages.Count - 1 do
    if CompareStrFlags(ALanguage, FLanguages[i]) then begin
      Result:=i;
      exit
    end;
end;

function tMngProjectA.SetLanguage;
var
  s: string;
  i: integer;
begin
  Result:=true;
  FLanguage:='';

  if GetLanguages and (FLanguages.Count > 0) then begin // если нет файлов локализации, то и хрен с ними - работаем по exe-файлу, ошибок не пишем!
    Result:=LoadCfl(fn_Language, s);

    if Result then begin
      i:=FindLanguage(s);
      if i >= 0 then FLanguage:=FLanguages[i];

      if FLanguage = '' then
        with tFListA.Create(nil) do
          try
            Caption:=list_language_Caption;
            Title:=list_language_Title;

//            Texts.New.Text:=list_language_Exe;
            for i:=0 to FLanguages.Count - 1 do Texts.New.Text:=FLanguages[i];

            Result:=ShowModal = mrOk;

            if Result then begin
              FLanguage:=FLanguages[Res];
              Result:=SaveCfl(fn_Language, FLanguage);
            end;

          finally
            Free;
          end;

      if Result and (FLanguage <> '') then (* Result:= *) LoadLanguageFile;      
    end;
  end;
end;

function tMngProjectA.SetWorkPath;
var s: string;
begin
  if CompareStrFlags(var_ExePath, var_WorkPath) then
    var_WorkPath:=NormalPath(var_WorkPath + c_pth_UserData
{$IFDEF NEWPATHS}
      + prj_RealExeNameWithOutExt
{$ENDIF}
      );

  Result:=LoadCfl(fn_Location, s);
  if Result then

    if s = location_Work then // ничего делать не надо, ибо уже var_WorkPath = рабочий каталог
    else
      if s = location_Roaming then var_WorkPath:=RoamingPathProject
      else

        with tFListA.Create(nil) do
          try
            Caption:=list_workpath_Caption;
            Title:=list_workpath_Title;

            with Texts.New do begin
              Add(list_workpath_2);
              Add(RoamingPath);
            end;
            with Texts.New do begin
              Add(list_workpath_1);
              Add(var_WorkPath);
            end;

            Result:=ShowModal = mrOk;

            if Result then
              if Res = 0 then begin
                var_WorkPath:=RoamingPathProject;
                Result:=SaveCfl(fn_Location, location_Roaming);
              end
              else
                Result:=SaveCfl(fn_Location, location_Work)
          finally
            Free;
          end;

  if Result then
    try
      if not DirectoryExists(var_WorkPath) then begin
        Result:=ForceDirectories(var_WorkPath);
        if not Result then log_err(Format(log_fs_err_ForceDirs, [var_WorkPath]))
      end;

      if Result then begin
        Result:=SetCurrentDir(var_WorkPath);
        if not Result then log_err(Format(log_fs_err_DirNotFound, [var_WorkPath]));
      end
    except
      Result:=false
    end;
end;

function tMngProjectA.Init; begin
  try
    InitBasic;
    InitVariables;
    InitApplication;
    InitConsole;
    tolog_MainInfo;

    Result:=
      SetLanguage and
      SetWorkPath;

    if Result then begin
      InitManagers;
      InitMainForm;
                   // отсюда
      InitTray;
      RegistryMainVars;
      LanguageToControls;

      InitAfter0;  // перенесено сверху

      LoadConfigs;
      InitAfter;

      Randomize;
    end;

  except
    Result:=false;
  end
end;

procedure tMngProjectA.Done; begin
  DoneLanguage;
  DoneBefore;
  SaveConfigs;
  DoneTray;
  DoneMainForm;
  DoneManagers;
  DoneConsole;
  DoneApplication;
  DoneVariables;
  DoneBasic;
end;



procedure tMngProjectA.InitBasic; begin
  FAboutLog:=tStringList.Create;
  FAboutLogEnabled:=false;
  FLanguages:=tStringList.Create;
  FInfoCache:=tDoubleStringList.Create;

  FMngResource:=tMngResource.Create;
end;

procedure tMngProjectA.InitVariables; begin
  var_log_Need:=false;
  Variables:=tVariables.Create('');
  var_log_FileName:='';

  // решил, что пусть сохран€ютс€ все под названи€ми exe-файла, а не имени проекта
  // чтобы было можно несколько копий сделать себе с разными настройками и играть поочереди
  prj_RealExeNameWithOutExt:=ChangeFileExt(ExtractFileName(Application.ExeName), '');

//  var_cfg_FileName:=prj_Name + ExtractFileExt(var_cfg_FileName);
  var_cfg_FileName:=ChangeFileExt(prj_RealExeNameWithOutExt, ExtractFileExt(var_cfg_FileName));

  fn_Save:=ChangeFileExt(var_cfg_FileName, fn_Ext_Save);
  fn_QuickSave:=Format(fn_QuickPart, [prj_RealExeNameWithOutExt, fn_Ext_Save]);

{$IFDEF NEWPATHS}
  pth_ViewStyles:=NormalPath(pth_ViewStyles + prj_Name);
  pth_Gameplay:=NormalPath(pth_Gameplay + prj_Name);
{$ENDIF}

  GlobalCompilerErrFunc:=OnGlobalCompilerErrFunc;
end;

procedure tMngProjectA.InitApplication; begin
  Application.Initialize;
  Application.Title:=ProjectTitle;
  Application.OnException:=OnAppException;
  Application.OnActivate:=OnAppActivate;
  Application.Icon.Assign(MngResource.Icon[res_icon_Main]);
end;

procedure tMngProjectA.InitConsole; begin
  Console:=tConsole.Create(nil);
  con_Width:=0.99;
  con_Extended:=true;
  con_ExtPos:=0;
  SetConsoleImage;
  Console.FuncOpenCfg:=ConsoleOpenCfg;
end;

procedure tMngProjectA.InitManagers; begin
  FMngControl:=tMngControl.Create;
  FMngGame:=tMngGame.Create;

  con_FontSize:=auto_FontSize;
end;

procedure tMngProjectA.InitMainForm; begin
  Application.CreateForm(tFMain, FMainForm);

  MainForm.Caption:=ProjectTitle;
  MainForm.RegistryVars;
  MainForm.Icon.Assign(MngResource.Icon[res_icon_Main]);

  VrfMainVars(@mf_Border);
end;

procedure tMngProjectA.InitTray;
var mi: tMenuItem;
begin
  FTrayMenu:=tPopupMenu.Create(nil);

  mi:=tMenuItem.Create(FTrayMenu);
  mi.OnClick:=tray_OnShowHide;
  FTrayMenu.Items.Add(mi);

  mi:=tMenuItem.Create(FTrayMenu);
  mi.Caption:='-';
  FTrayMenu.Items.Add(mi);

  mi:=tMenuItem.Create(FTrayMenu);
  mi.Caption:=menu_tray_Quit;
  mi.OnClick:=tray_OnQuit;
  FTrayMenu.Items.Add(mi);

  FTray:=tspTrayIcon.Create(MainForm, ProjectTitle, false);
  FTray.Icon:=MngResource.Icon[res_icon_Tray];
  FTray.OnDblClick:=OnTrayDblClick;
  FTray.OnClick:=OnTrayClick;
  FTray.BeforePopup:=OnTrayBeforePopup;
  FTray.PopupMenu:=FTrayMenu;

  FTray.Active:=tray_AlwaysIcon;
end;

procedure tMngProjectA.LoadConfigs; begin
  with Variables do begin
//    LoadConfig(var_ExePath + pth_ViewStyles + fn_Default + fn_Ext_Cfg);
//    LoadConfig(var_ExePath + pth_Gameplay + fn_Default + fn_Ext_Cfg);

    LoadConfig(var_WorkPath + var_cfg_FileName);
    LoadAutoExec(var_WorkPath + var_cfg_AutoExec);
    LoadAutoExec(var_ExePath + var_cfg_AutoExec);
    TranslateParam;
    BeforeRunApp;
  end;

  Load(fn_Save);
end;

procedure tMngProjectA.InitAfter0; begin
  MngGame.Init0;
end;

procedure tMngProjectA.InitAfter; begin
  MngGame.Init;
  MngControl.AddSource(MainForm);
end;



procedure tMngProjectA.DoneBefore; begin
end;

procedure tMngProjectA.SaveConfigs; begin
  Save(fn_Save);
  Variables.SaveConfig(var_WorkPath + var_cfg_FileName);
end;

procedure tMngProjectA.DoneTray; begin
  FTray.Free;
  FTrayMenu.Free;
end;

procedure tMngProjectA.DoneMainForm; begin
  FMainForm.Free;
end;

procedure tMngProjectA.DoneManagers; begin
  FMngGame.Free;
  FMngControl.Free;
end;

procedure tMngProjectA.DoneConsole; begin
  Console.Free;
end;

procedure tMngProjectA.DoneApplication; begin
  Application.OnActivate:=nil;
  Application.OnException:=nil;
end;

procedure tMngProjectA.DoneVariables; begin
  GlobalCompilerErrFunc:=nil;
  Variables.Free;
end;

procedure tMngProjectA.DoneBasic; begin
  FMngResource.Free;
  FLanguages.Free;
  FAboutLog.Free;
  FInfoCache.Free;
end;



procedure tMngProjectA.RegistryMainVars;
var i: integer;
begin
  with Variables do begin
    RegistryString(vn_iwg_Version, iwg_Version, nil, nil, true);
    RegistryString(vn_prj_Version, prj_Version, nil, nil, true);

    prj_NameR:=ProjectTitle;
    RegistryString(vn_prj_Name, prj_NameR, nil, nil, true);
    RegistryString(vn_prj_NameA, prj_Name, nil, nil, true);

    RegistryString(vn_fn_Save, fn_Save, nil, nil, true);
    RegistryString(vn_fn_QuickSave, fn_QuickSave, nil, nil, true);
    RegistryString(vn_pth_SaveGames, pth_SaveGames, nil, nil, true);
    RegistryString(vn_pth_Gameplay, pth_Gameplay, nil, nil, true);
    RegistryString(vn_pth_ViewStyles, pth_ViewStyles, nil, nil, true);
    RegistryString(vn_pth_Help, pth_Help, nil, nil, true);

    RegistryString(vn_pth_Work, var_WorkPath, nil, nil, true);
    RegistryString(vn_pth_Exe, var_ExePath, nil, nil, true);

    RegistryFunction(vn_prj_Quit, @tMngProjectA.prjQuit, self, vtVoid, []);
    RegistryFunction(vn_prj_Minimize, @tMngProjectA.prjMinimize, self, vtVoid, []);
    RegistryFunction(vn_prj_HideToTray, @tMngProjectA.prjHideToTray, self, vtVoid, []);

    // QuickSave, QuickSaveEx, QuickLoad регить не стал
    RegistryFunction(vn_prj_Save, @tMngProjectA.SaveDef, self, vtVoid, [vtString]);
    RegistryFunction(vn_prj_SaveEx, @tMngProjectA.SaveEx, self, vtVoid, [vtString]);
    RegistryFunction(vn_prj_Load, @tMngProjectA.LoadDef, self, vtVoid, [vtString]);
    RegistryFunction(vn_prj_About, @tMngProjectA.About, self, vtVoid, []);

    RegistryFunction(vn_prj_Help, @tMngProjectA.Help, self, vtVoid, []);
    RegistryFunction(vn_prj_ViewStyles, @tMngProjectA.ViewStyles, self, vtVoid, [vtString]);
    RegistryBoolean(vn_prj_templates_Mode, prj_templates_Mode);
    RegistryFunction(vn_prj_Gameplay, @tMngProjectA.Gameplay, self, vtVoid, [vtString]);

    RegistryFunction(vn_prj_iLog, @tMngProjectA.iLog, self, vtVoid, [vtString]);

    RegistryInteger(vn_mf_Border, mf_Border, self, VrfMainVars);

    RegistryBoolean(vn_tray_AlwaysIcon, tray_AlwaysIcon, self, VrfMainVars);
    RegistryBoolean(vn_exception_Show, exception_Show);

    RegistryFunction(vn_prj_droplocation, @tMngProjectA.DropLocation, self, vtVoid, []);
    RegistryFunction(vn_prj_droplanguage, @tMngProjectA.DropLanguage, self, vtVoid, []);

    RegistryFunction(vn_math_Min, @tMngProjectA.math_Min, self, vtInteger, [vtInteger, vtInteger]);
    RegistryFunction(vn_math_Max, @tMngProjectA.math_Max, self, vtInteger, [vtInteger, vtInteger]);

    RegistryString(vn_lng_Name, FLanguage, nil, nil, true);

    for i:=low(prj_Temp) to high(prj_Temp) do RegistryString(Format(vn_temp, [i]), prj_temp[i]);
  end;

  with MngControl do begin
    RegistryControl(self, ctrl_Console, key_Console);
    Bind(key_Console2, ctrl_Console);
    Bind(key_Console3, ctrl_Console);

    RegistryControl(self, ctrl_Quit, key_Quit);
    RegistryControl(self, ctrl_Minimize, key_Minimize);
    RegistryControl(self, ctrl_Tray, key_Tray);

    RegistryControl(self, ctrl_Save, key_None);
    RegistryControl(self, ctrl_SaveEx, key_None);
    RegistryControl(self, ctrl_Load, key_None);
    RegistryControl(self, ctrl_QuickSave, key_QuickSave);
    RegistryControl(self, ctrl_QuickSaveEx, key_None);
    RegistryControl(self, ctrl_QuickLoad, key_QuickLoad);
    RegistryControl(self, ctrl_About, key_None);

    RegistryControl(self, ctrl_Help, key_None);
    RegistryControl(self, ctrl_ViewStyles, key_None);
    RegistryControl(self, ctrl_Gameplay, key_None);
  end;
end;

function tMngProjectA.VrfMainVars;
var ExStyle: cardinal;
begin
  if PtrValue = @mf_Border then begin
    Result:=(mf_Border in [mfb_Min..mfb_Max]);

    if Result then begin
      Console.Exit;

      with MainForm do begin
        case mf_Border of
          mfb_Single:         BorderStyle:=bsSingle;
          mfb_SingleNoButton: BorderStyle:=bsSingle;
          mfb_None:           BorderStyle:=bsNone;
          mfb_ToolEasy,
          mfb_Tool: begin
            BorderStyle:=bsToolWindow;
            ExStyle:=GetWindowLong(Handle, GWL_EXSTYLE);
            if mf_Border = mfb_ToolEasy then ExStyle:=ExStyle and not WS_EX_TOOLWINDOW
            else ExStyle:=ExStyle or WS_EX_TOOLWINDOW;
            SetWindowLong(Handle, GWL_EXSTYLE, ExStyle);
          end;
        end;

        if mf_Border in [mfb_Single, mfb_ToolEasy] then BorderIcons:=[biSystemMenu]
        else BorderIcons:=[]
      end;

      MngGame.ChangeGameForm;
    end;
  end
  else begin
    Result:=true;
    if PtrValue = @tray_AlwaysIcon then FTray.Active:=tray_AlwaysIcon
  end
end;

procedure tMngProjectA.SetConsoleImage;
var
  j: tJpegImage;
begin
  j:=MngResource.LoadJpeg(res_jpeg_Console);
  if j <> nil then begin
    Console.AssignMainImage(j);
    j.Free
  end;
end;

procedure tMngProjectA.tolog_MainInfo; begin
  FAboutLogEnabled:=true;
  try
    log(Format(iwg_ProjectInfo, [ProjectTitle, prj_Version]), logBold);
    log(Format(iwg_EngineInfo, [iwg_Version]), logLine);
    log(iwg_Copyright, logBold);
    log(Format(iwg_iwerg_email, [iwerg_email]), logLine);
    log(Format(iwg_by, [lowerstr(con_VersionValue), iwg_iwerg]));
    log(Format(iwg_by, [lowerstr(PCVersion), Format(iwg_people3, [iwg_people_wna, iwg_people_spectre, iwg_iwerg])]));

    tMngGame.tolog_MainInfoGame;

    log(iwg_Remastering, pointer(_logBold + _logLinePrev));
  finally
    FAboutLogEnabled:=false;
  end
end;

procedure tMngProjectA.OnGlobalCompilerErrFunc; begin
  Variables.Error(AError)
end;

procedure tMngProjectA.OnAppActivate; begin
  inherited;
  InitFormats
end;

procedure tMngProjectA.OnAppException; begin
  inherited;
  log_err(Format(log_prj_Exception, [AException.Message]));
  if exception_Show then Application.ShowException(AException);
end;

procedure tMngProjectA.OnTrayDblClick; begin
  if FTray.Minimized then FTray.Restore;
end;

procedure tMngProjectA.OnTrayClick; begin
  if not FTray.Minimized and (AButton = mbLeft) then begin
    SetForegroundWindow(MainForm.Handle);
    if Console.Visible then SetForegroundWindow(Console.Handle);
  end;
end;

procedure tMngProjectA.OnTrayBeforePopup; begin
  if FTray.Minimized then FTrayMenu.Items[0].Caption:=menu_tray_Show
  else FTrayMenu.Items[0].Caption:=menu_tray_Hide
end;

procedure tMngProjectA.BeforeTerminate; begin
  MngGame.PauseOnly
end;

procedure tMngProjectA.prjQuit; begin
  MainForm.Close
end;

procedure tMngProjectA.prjMinimize; begin
  Console.Exit;
  Application.Minimize;
end;

procedure tMngProjectA.prjHideToTray; begin
  Console.Exit;
  FTray.Minimize
end;

procedure tMngProjectA.tray_OnQuit; begin
  prjQuit
end;

procedure tMngProjectA.tray_OnShowHide; begin
  if FTray.Minimized then FTray.Restore
  else prjHideToTray;
end;

procedure tMngProjectA.BringToFront; begin
//  Application.BringToFront;
  if FTray.Minimized then FTray.Restore
  else begin
    Application.Minimize;
    Application.Restore;
  end;
end;

function tMngProjectA.DialogExecute; begin
  with ADialog do begin
    Filter:=AFilter;
    InitialDir:=AInitialDir;
    DefaultExt:=AExt;

    Result:=Execute(MainForm.Handle);
    if Result then AFileName:=FileName;

    try
      SetCurrentDir(var_WorkPath)
    except
    end;
  end;
end;

function tMngProjectA.VerifyFileName;
var s, s2: string;
begin
  if ANextDir = '' then ANextDir:=pth_SaveGames
  else
    if ANextDir = '.' then ANextDir:='';

  AFileName:=DelRSpace(AFileName);
  Result:=length(AFileName) > 0;
  if Result then begin

    if length(ExtractFileExt(AFileName)) = 0 then s2:=AFileName + fn_Ext_Save
    else s2:=AFileName;

    s:=var_WorkPath + ANextDir;
    if not DirectoryExists(s) then Result:=ForceDirectories(s);

    if Result then AFileName:=ExpandUncFileNameEx(s, s2)
    else Setlength(AFileName, 0)
  end
end;

procedure tMngProjectA.Save;
var
  od: tSaveDialog;
  s : string;
begin
  if not VerifyFileName(AFileName, ANextDir) then begin
    od:=tSaveDialog.Create(MainForm);
    try
      s:=var_WorkPath + ANextDir;
      if not DirectoryExists(s) then ForceDirectories(s);
      DialogExecute(od, AFileName, fn_Filter_Save, s, fn_Ext_Save);
    finally
      od.Free;
    end;
  end;

  if length(AFileName) > 0 then MngGame.SaveGameToConfig(AFileName, AEx);
end;

procedure tMngProjectA.Load;
var
  od: tOpenDialog;
  s : string;
begin
  if not VerifyFileName(AFileName, ANextDir) then begin
    od:=tOpenDialog.Create(MainForm);
    try
      s:=var_WorkPath + ANextDir;
      if not DirectoryExists(s) then ForceDirectories(s);
      DialogExecute(od, AFileName, fn_Filter_Save, s, fn_Ext_Save);
    finally
      od.Free;
    end;
  end;

  if length(AFileName) > 0 then MngGame.LoadGameFromConfig(AFileName);
end;

procedure tMngProjectA.SaveDef; begin
  Save(AFileName, '');
end;

procedure tMngProjectA.SaveEx; begin
  Save(AFileName, '', true);
end;

procedure tMngProjectA.LoadDef; begin
  Load(AFileName, '');
end;

procedure tMngProjectA.About; begin
  Console.Exit;

  with tFAbout.Create(MainForm) do begin
    ShowModal;
    Free
  end
end;

procedure tMngProjectA.Help;
var s, hn: string;
begin
  if LowerStr(Flanguage) = 'русский' then s:='rus'
  else s:='eng';

  hn:=Format(fn_Help, [ReplaceStr(prj_Name, ' ', '_'), s]);
  s:=var_ExePath + c_pth_Help + hn;

  if FileExists(s) then ShellEx(s)
  else begin
    log_err(Format(log_fs_err_FileNotFound, [s]));

    ShellEx('http://games.ich.su/games/windows/help/' + hn);
  end;
end;

function tMngProjectA.ShowTemplatesNew; begin
  with tFListVS.Create(MainForm) do
    try
      Easy:=AEasy;
      if not AEasy then Position:=poDesigned;
      
      Caption:=ACaption;
      Title:=ATitle;
      if not LoadConfigs(var_ExePath + APath) then Result:=mrRetry
      else Result:=ShowModal; // если = mrRetry, то открывать конфигами!
    finally
      Free
    end;
end;

function tMngProjectA.ViewStylesNew; begin
  Result:=ShowTemplatesNew(list_appearance_Caption, list_appearance_Title, pth_ViewStyles, false);
end;

function tMngProjectA.GameplayNew; begin
  Result:=ShowTemplatesNew(list_gameplay_Caption, list_gameplay_Title, pth_Gameplay, true);
end;

procedure tMngProjectA.LoadTemplate;
var
  od: tOpenDialog;
  s : string;
begin
  AFileName:=DelRSpace(AFileName);
  s:=ADir;

  if length(AFileName) > 0 then begin
    AFileName:=ExpandUncFileNameEx(s, AFileName);
    if length(ExtractFileExt(AFileName)) = 0 then AFileName:=AFileName + fn_Ext_Cfg
  end
  else begin
    od:=tOpenDialog.Create(MainForm);
    if not DirectoryExists(s) then begin
      log_err(Format(log_fs_err_DirNotFound, [s]));
      s:=var_ExePath;
    end;

    if DialogExecute(od, AFileName, fn_Filter_Cfg, s, fn_Ext_Cfg) then
      if Console.Visible then Console.BringToFront;
      
    od.Free;
  end;

  if length(AFileName) > 0 then begin
    Exec(AFileName);
    FInfoCache.Clear;
  end;
end;

procedure tMngProjectA.ViewStyles; begin
  if length(AFileName) > 0 then LoadTemplate(AFileName, var_ExePath + pth_ViewStyles)
  else
    if (not prj_templates_Mode) or
       (ViewStylesNew = mrRetry) then LoadTemplate('', var_ExePath + pth_ViewStyles)
end;

procedure tMngProjectA.Gameplay; begin
  if length(AFileName) > 0 then LoadTemplate(AFileName, var_ExePath + pth_Gameplay)
  else
    if (not prj_templates_Mode) or
       (GameplayNew = mrRetry) then LoadTemplate('', var_ExePath + pth_Gameplay)
end;

procedure tMngProjectA.ConsoleOpenCfg; begin
  LoadTemplate('', var_ExePath + pth_ViewStyles + '..\console\');
end;

procedure tMngProjectA.Exec(AConfig: tStringList);
var Compiler: tCompiler;
begin
  MngGame.LockChangeGameForm(true);
  Compiler:=tCompiler.Create(Variables);
  try
    Variables.VerifyOpenClose(AConfig);
    Compiler.Translate(AConfig, false, true, var_MaxTranslateTime)
  finally
    Compiler.Free;
    MngGame.LockChangeGameForm(false);
  end
end;

procedure tMngProjectA.Exec(AFileName: string);
var Compiler: tCompiler;
begin
  MngGame.LockChangeGameForm(true);
  Compiler:=tCompiler.Create(Variables);
  try
    Variables.LoadFromFile(AFileName, Compiler, '', var_MaxTranslateTime)
  finally
    Compiler.Free;
    MngGame.LockChangeGameForm(false);
  end
end;

function tMngProjectA.OnControl; begin
  Result:=inherited OnControl(ASender, AControl);

  if AControl = ctrl_Quit then prjQuit else
  if AControl = ctrl_Minimize then prjMinimize else
  if AControl = ctrl_Tray then prjHideToTray else

  if AControl = ctrl_Save then Save('', '') else
  if AControl = ctrl_SaveEx then Save('', '', true) else
  if AControl = ctrl_Load then Load('', '') else
  if AControl = ctrl_QuickSave then Save(fn_QuickSave, '') else
  if AControl = ctrl_QuickSaveEx then Save(fn_QuickSave, '', true) else
  if AControl = ctrl_QuickLoad then Load(fn_QuickSave, '') else

  if AControl = ctrl_ViewStyles then ViewStyles('') else
  if AControl = ctrl_Gameplay then Gameplay('') else

  if AControl = ctrl_About then About else
  if AControl = ctrl_Help then Help else

  if AControl = ctrl_Console then
    if not Console.Visible then Console.Exec
    else Console.Exit
  else
end;

procedure tMngProjectA.iLog;
var
  sl: tStringList;
  i : integer;
begin
  if length(AFileName) = 0 then log_err(Format(log_err_invalidarg, [vn_prj_iLog]))
  else begin

    sl:=tStringList.Create;

    with Variables do
      for i:=0 to Count - 1 do sl.Add(Name[i]);
    sl.Add('');
    MngControl.iLog(sl);

    try
      sl.SaveToFile(AFileName);;
      log(Format(ms_var_Save, [AFileName]))
    except
      log_err(Format(ms_var_ErrorSave, [AFileName]))
    end;

    sl.Free
  end;
end;

function tMngProjectA.math_Min; begin
  Result:=Math.Min(V1, V2);
end;

function tMngProjectA.math_Max; begin
  Result:=Math.Max(V1, V2);
end;

function tMngProjectA.RoamingPath; begin
  Result:=NormalPath(GetSpecialPath(CSIDL_APPDATA)) + c_pth_RoamingAdd;
end;

function tMngProjectA.RoamingPathProject; begin
//  Result:=NormalPath(RoamingPath + prj_Name); // ProjectTitle);
  Result:=NormalPath(RoamingPath + prj_RealExeNameWithOutExt); // почему так - смотри в tMngProjectA.InitVariables
end;

end.

