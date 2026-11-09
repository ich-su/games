{$I defines.inc}
unit c_strings;

interface

uses IniFiles;

const
  iwg_iwerg                     = 'ich';
  iwg_Copyright                 = '© sergey lebedev aka ' + iwg_iwerg + ', 2007';
  iwg_Remastering               = 'remastering by ich, 2017';
  iwg_ProjectInfo               = '%0s, v%1s';
  iwg_EngineInfo                = (* {$I ..\_version\prefix_projects.} + *) 'games engine, v%0s';
  iwg_iwerg_email               = 'email <%0s>';
  iwg_iwerg_icq                 = 'icq <%0s>';

  iwerg_email                   = 'ich@ich.su';
//  iwerg_icq                     = '175109632';

  iwg_by                        = '%0s by %1s';

  iwg_people_Spectre            = 'spectre';
  iwg_people_wna                = 'wna';
  iwg_people3                   = '%0s, %1s and %2s';

  iwg_16QuadColors              = '16 colors quad pallete';
  iwg_BetaTesting               = 'beta testing';




  
  log_prj_Exception             : string = 'exception <%s>';

  log_ctrl_Bind                 = '%s --> %s';
  log_ctrl_Str                  = '%s';
  log_ctrl_Control              = '%s <-- %s';
  log_ctrl_ControlAlias         = '--> %s';
  log_ctrl_AddEsl               = ' (%s)';

  log_ctrl_err_InvalidControl   : string = 'invalid control <%0s>';
  log_ctrl_err_InvalidKey       : string = 'invalid key <%0s>';
  log_ctrl_err_CannotAssign     : string = 'cannot assign control <%0s>';
  log_ctrl_err_CannotDelete     : string = 'cannot delete control <%0s>';
  log_ctrl_err_InvalidEslString : string = 'invalid esl-string <%0s>';
  log_fs_err_DirNotFound        : string = 'folder not found <%0s>';
  log_fs_err_ForceDirs          : string = 'error creating directories <%0s>';
  log_fs_err_FileNotFound       : string = 'file not found <%0s>';
  log_fs_err_ScanDir            : string = 'error reading folder <%0s>';
  log_fs_inf_ScanDir            : string = 'reading folder <%0s>';
  log_fs_DeleteFile             : string = 'file deletion <%0s>';
  log_fs_err_DeleteFile         : string = 'file deletion error <%0s>';

  log_frm_Create                : string = 'creating form <%0s>';
  log_frm_Free                  : string = 'deleting form <%0s>';

  log_game_Start                : string = 'starting game';
  log_game_Pause                : string = 'pausing game';
  log_game_Stop                 : string = 'stopping game';

  log_game_GameInfoTime         : string = 'time <%0s>';
  log_game_GameInfoScore        : string = 'score <%0s>';
  log_game_StateChange          = '%s, %s';

  log_game_tetris_KillQuad      : string = 'quads killed <%0s>';
  log_game_tetris_KillLine      : string = 'lines killed <%0s>';
  log_game_click_Quads          : string = 'quads <%0s>';

  log_err_invalidarg            : string = '%0s: invalid argument';

  log_color_Empty               : string = 'colors not found ;(';
  log_color_List                = 'color%d = %s';
  log_game_QuadCountChanceList  = 'count = %d <-- %d y.e.';





  menu_tray_Quit                : string = 'Quit';
  menu_tray_Show                : string = 'Show';
  menu_tray_Hide                : string = 'Hide';





  save_Chars                    = 'cfs';





  vn_iwg_Version                = 'eng_Version';
  vn_prj_Version                = 'prj_Version';
  vn_prj_Name                   = 'prj_Name';
  vn_prj_NameA                  = 'prj_NameA';
  vn_save_Version               = save_Chars + '_Version';

  vn_prj_About                  = 'about';
  vn_prj_Quit                   = 'quit';
  vn_prj_Minimize               = 'minimize';
  vn_prj_HideToTray             = 'hidetotray';

  vn_prj_Save                   = 'save';
  vn_prj_SaveEx                 = 'saveex';
  vn_prj_Load                   = 'load';
  vn_prj_QuickSave              = 'quicksave';   
  vn_prj_QuickSaveEx            = 'quicksaveex';
  vn_prj_QuickLoad              = 'quickload';
  vn_prj_Help                   = 'help';
  vn_prj_ViewStyles             = 'appearance';
  vn_prj_Gameplay               = 'gameplay';
  vn_prj_templates_Mode         = 'templates_mode';
  vn_prj_iLog                   = 'ilog';

  vn_game_NewGame               = 'newgame';

  vn_fn_Save                    = 'var_save_FileName';
  vn_fn_QuickSave               = 'var_quicksave_FileName';
  vn_pth_SaveGames              = 'var_pth_SaveGames';
  vn_pth_Gameplay               = 'var_pth_Gameplay';
  vn_pth_ViewStyles             = 'var_pth_Appearance';
  vn_pth_Help                   = 'var_pth_Help';
  vn_pth_Exe                    = 'var_pth_Exe';
  vn_pth_Work                   = 'var_pth_Work';
  vn_exe_FileName               = 'var_exe_FileName';

  vn_mf_Top                     = 'form_Top';
  vn_mf_Left                    = 'form_Left';
  vn_mf_Width                   = 'form_Width';
  vn_mf_Height                  = 'form_Height';
  vn_mf_Border                  = 'form_Style';
  vn_mf_BackColor               = 'form_BackColor';
  vn_mf_NCHITTEST               = 'form_NChitTest';
  vn_mf_CaptionLive             = 'form_CaptionLive';

  vn_mf_BorderColor             = 'form_BorderColor';
  vn_mf_NothingSize             = 'form_SpaceAround';
  vn_mf_NothingSizeLeft         = 'form_SpaceLeft';
  vn_mf_NothingSizeRight        = 'form_SpaceRight';
  vn_mf_NothingSizeTop          = 'form_SpaceTop';
  vn_mf_NothingSizeBottom       = 'form_SpaceBottom';

  vn_mf_BackImage               = 'form_BackImage';
  vn_mf_BackImageFileName       = 'form_BackImageFileName';
  vn_mf_BackImageScaled         = 'form_BackImageScale';

  vn_g_BackImage                = 'board_BackImage';
  vn_g_BackImageFileName        = 'board_BackImageFileName';
  vn_g_BackImageScaled          = 'board_BackImageScale';
  vn_g_BackImageShift           = 'board_BackImageShift';
  vn_g_BackImageShiftX          = 'board_BackImageShiftX';
  vn_g_BackImageShiftY          = 'board_BackImageShiftY';

  vn_g_RowCount                 = 'board_RowCount';
  vn_g_ColCount                 = 'board_ColCount';
  vn_g_CellSize                 = 'board_CellSize';
  vn_g_BackColor                = 'board_BackColor';
  vn_g_BorderColor              = 'board_BorderColor';
  vn_g_NothingSize              = 'board_SpaceAround';

  vn_g_QuadColor                = 'quad_Color';
  vn_g_SetQuadColor             = 'SetQuadColor';
  vn_g_QuadBorderColor          = 'quad_BorderColor';
  vn_g_QuadNothingSize          = 'quad_NothingSize';
  vn_g_QuadCountMin             = 'quad_CountMin';
  vn_g_QuadCountMax             = 'quad_CountMax';
  vn_g_QuadCountChance          = 'SetQuadCountChance';
  vn_g_QuadCountChanceList      = 'quad_CountChanceList';

  vn_g_QuadBorderStyle          = 'quad_BorderStyle';  // click
  vn_g_QuadDieMouseDown         = 'quad_DieMouseDown';

  vn_g_QuadColorCount           = 'quad_ColorCount';
  vn_g_QuadDieMinCount          = 'quad_DieMinCount';
  vn_g_QuadColorList            = 'quad_ColorList';

  vn_g_QuadDieSpeed             = 'quad_DieSpeed';
  vn_g_QuadDieStyle             = 'quad_DieStyle';
  vn_g_QuadDieStyle1ParamWait   = 'quad_DieStyle1ParamWait';
  vn_g_QuadDieStyle2ParamCount  = 'quad_DieStyle2ParamCount';
  vn_g_QuadDieStyle2ParamWait   = 'quad_DieStyle2ParamWait';

  vn_g_QuadDieColorEnabled      = 'quad_DieColorEnabled';
  vn_g_QuadDieColor             = 'quad_DieColor';
  vn_g_QuadDieBorderColor       = 'quad_DieBorderColor';

  vn_g_QuadMouseDownColor       = 'quad_MouseDownColor';

  vn_g_QuadAloneDropEnabled     = 'quad_DropAlone';
  vn_g_KillLine                 = 'quad_KillLine';
  vn_g_KillColors               = 'quad_KillColor';

  vn_g_BrickSpeed               = 'brick_Speed';
  vn_g_BrickDropSpeed           = 'brick_DropSpeed';
  vn_g_BrickDropQuick           = 'brick_DropQuick';
  vn_g_BrickRotateSkirting      = 'brick_RotateSkirting';

  vn_g_WallColorEnabled         = 'wall_ColorEnabled';
  vn_g_WallColor                = 'wall_Color';
  vn_g_WallBorderColor          = 'wall_BorderColor';

  vn_info_Enabled               = 'info_Show';
  vn_info_BoardRect             = 'info_BoardRect';
  vn_info_FontColor             = 'info_FontColor';
  vn_info_ControlFontColor      = 'info_ControlFontColor';
  vn_info_ControlFontColorLight = 'info_ControlFontColorLight';
  vn_info_FontName              = 'info_FontName';
  vn_info_FontSize              = 'info_FontSize';
  vn_info_FontStyle             = 'info_FontStyle';
  vn_info_TextFontColor         = 'info_TextFontColor';
  vn_info_TextFontName          = 'info_TextFontName';
  vn_info_TextFontSize          = 'info_TextFontSize';
  vn_info_TextFontStyle         = 'info_TextFontStyle';
  vn_info_VSpace                = 'info_VSpace';
  vn_info_HSpace                = 'info_HSpace';
  vn_info_Y                     = 'info_Y';
  vn_info_X                     = 'info_X';
  vn_info_Translate             = 'info_Translate';

  vn_info_NextBrick             = 'info_NextBrick';
  vn_info_NextBrickCellSize     = 'info_NextBrickCellSize';
  vn_info_NextBrickCount        = 'info_NextBrickCount';
  vn_info_NextBrickNothingSize  = 'info_NextBrickNothingSize';
  vn_info_NextBrickBorderColor  = 'info_NextBrickBorderColor';
  vn_info_NextBrickColor        = 'info_NextBrickColor';
  vn_info_NextBrickHSpace       = 'info_NextBrickHSpace';

  vn_info_Left                  = 'info_Left';
  vn_info_LeftStarted           = 'info_LeftStarted';
  vn_info_Right                 = 'info_Right';
  vn_info_RightStarted          = 'info_RightStarted';

  vn_tray_AlwaysIcon            = 'tray_AlwaysShowIcon';
  vn_exception_Show             = 'exception_Show';

  vn_ctrl_Bind                  = 'bind';
  vn_ctrl_Unbind                = 'unbind';
  vn_ctrl_UnbindAll             = 'unbindall';
  vn_ctrl_Binds                 = 'binds';
  vn_ctrl_Control               = 'control';
  vn_ctrl_DelControl            = 'delcontrol';
  vn_ctrl_DelControlAll         = 'delcontrolall';
  vn_ctrl_Controls              = 'controls';
  vn_ctrl_MaxTime               = 'ctrl_esl_TimeOut';

  vn_screen_Width               = 'desktop_Width';
  vn_screen_Height              = 'desktop_Height';
  vn_screen_Left                = 'desktop_Left';
  vn_screen_Top                 = 'desktop_Top';
  vn_screen_PPI                 = 'desktop_PPI';

  vn_auto_CellSize              = 'auto_CellSize';
  vn_auto_FontSize              = 'auto_FontSize';
  vn_auto_SmallFontSize         = 'auto_SmallFontSize';

  vn_canvas_TextWidth           = 'canvas_TextWidth';
  vn_canvas_TextHeight          = 'canvas_TextHeight';

  vn_math_Min                   = 'math_Min';
  vn_math_Max                   = 'math_Max';

  vn_lng_Name                   = 'lng_Name';

  vn_temp                       = 'temp_%0d';





  cfg_ctrl_begin                = vn_ctrl_unbindall + ';';
  cfg_ctrl_bind                 = 'bind(%s, %s);';
  cfg_ctrl_bindSign             = 'bind(';
  cfg_ctrl_control              = 'control(%s, %s);';
  cfg_ctrl_SignA                = '%s =';

  cfg_game_obj_QuadCountChance  = vn_g_QuadCountChance + '(%d, %d);';
  cfg_mcolor_func               = '(%d, %s);';





  ctrl_About                    = 'about';
  ctrl_Console                  = 'console';
  ctrl_Quit                     = vn_prj_Quit;
  ctrl_Minimize                 = vn_prj_Minimize;
  ctrl_Tray                     = vn_prj_HideToTray;

  ctrl_Start                    = 'start';
  ctrl_Play                     = 'play'; // = start
  ctrl_Pause                    = 'pause';
  ctrl_Stop                     = 'stop';
  ctrl_PauseOnly                = 'pauseonly';
  ctrl_UnPauseOnly              = 'unpauseonly';
  ctrl_PlayPause                = 'playpause';

  ctrl_Save                     = vn_prj_Save;
  ctrl_SaveEx                   = vn_prj_SaveEx;
  ctrl_Load                     = vn_prj_Load;
  ctrl_QuickSave                = vn_prj_QuickSave;
  ctrl_QuickSaveEx              = vn_prj_QuickSaveEx;
  ctrl_QuickLoad                = vn_prj_QuickLoad;

  ctrl_Help                     = vn_prj_Help;
  ctrl_ViewStyles               = vn_prj_ViewStyles;
  ctrl_Gameplay                 = vn_prj_Gameplay;

  ctrl_NewGame                  = vn_game_NewGame;

  ctrl_game_MoveLeft            = 'moveleft';
  ctrl_game_MoveRight           = 'moveright';
  ctrl_game_MoveUp              = 'moveup';
  ctrl_game_MoveDown            = 'movedown';
  ctrl_game_RotateLeft          = 'rotateleft';
  ctrl_game_RotateRight         = 'rotateright';
  ctrl_game_ShiftDown           = 'shiftdown';
  ctrl_game_ShiftUp             = 'shiftup';
  ctrl_game_Drop                = 'drop';
  ctrl_game_Next                = 'next';
  ctrl_game_Prev                = 'prev';

  ctrl_game_Stop                = 'game_Stop'; // именно этот стоп вызывать из tGameObjectXXX и tMngGameXXX
  ctrl_game_obj_Draw            = 'go_draw';
  ctrl_game_obj_GameLoop        = 'go_gameloop';
  ctrl_game_MouseEvent          = 'game_mouseevent';

  cfgr_info_Left                = '%s---time-time --score-score %s';
  cfgr_info_Tetris1             = '--quadskilled-quads killed';
  cfgr_info_Tetris2             = '--lineskilled-lines killed';
  cfgr_info_TetrisNext          = '---next bricks:--';
  cfgr_info_Right               = 'console---settings:--appearance--gameplay---help:--help--about---form:--minimize--hide to tray----quit';
  cfgr_info_LeftClick           = '%s---time-time --quads-quads ----';





  info_Time                     = 'time';
  info_Scores                   = 'score';
  info_Title                    = 'title';

  info_KillQuad                 = 'quadskilled';
  info_KillLine                 = 'lineskilled';

  info_Quads                    = 'quads'; // click

  info_B                        = 'b^';
  info_U                        = 'u^';
  info_I                        = 'i^';





  caption_Format                = '%s - %s';
  c_caption_Paused              = 'paused';
  c_caption_GameOver            = 'game over';
  c_caption_NewGame             = 'new game';
  caption_Paused                : string = c_caption_Paused;
  caption_GameOver              : string = c_caption_GameOver;
  caption_NewGame               : string = c_caption_NewGame;





  key_Console                   = 'esc';
  key_Console2                  = '`';
  key_Console3                  = 'ctrl+`';
  key_Quit                      = 'alt+q';
  key_Minimize                  = 'alt+w';
  key_Tray                      = 'alt+e';

  key_Start                     = 's';
  key_Start2                    = 'enter';
  key_Stop                      = 'ctrl+s';
  key_Pause                     = 'p';
  key_Pause2                    = 'pause';
  key_PauseOnly                 = 'ctrl+p';
  key_PauseOnly2                = 'ctrl+pause';

  key_QuickSave                 = 'f6';
  key_QuickLoad                 = 'f9';





  key_c_Left                    = 'left';
  key_c_Right                   = 'right';
  key_c_Up                      = 'up';
  key_c_Down                    = 'down';
  key_c_Space                   = 'space';

  key_None                      = '';





  keyname_pause                 = 'pause';
  keyname_win1                  = 'win1';
  keyname_win2                  = 'win2';
  keyname_numlock               = 'numlock';

  keyname_mouseleft             = 'mouseleft';
  keyname_mouseright            = 'mouseright';
  keyname_mousemiddle           = 'mousemiddle';

  keyname_mousewheelup          = 'mousewheelup';
  keyname_mousewheeldown        = 'mousewheeldown';





  res_icon_Main                 = 'ICON_MAIN';
  res_icon_Tray                 = 'ICON_TRAY';
  res_jpeg                      = 'JPEG';
  res_jpeg_Console              = 'JPEG_CONSOLE';
  res_jpeg_Back                 = 'JPEG_BACK%d';
  res_jpeg_About_96             = 'JPEG_ABOUT_96';
  res_jpeg_About_120            = 'JPEG_ABOUT_120';
  res_jpeg_About_144            = 'JPEG_ABOUT_144';





  fn_Ext_Lng                    = '.lng';
  fn_Ext_Save                   = '.' + save_Chars;
  fn_QuickPart                  = '%s_quick%s';
  fn_Filter_Save                = 'saved games (*' + fn_Ext_Save + ')|*' + fn_Ext_Save;
  fn_Ext_Cfg                    = '.cfg';
  fn_Filter_Cfg                 = 'configs (*' + fn_Ext_Cfg + ')|*' + fn_Ext_Cfg;
  fn_Location                   = 'location.cfl';
  fn_Language                   = 'language.cfl';
  fn_Default                    = 'default';

  fn_Help                       = '%s_%s.html';

  save_Title                    = '--- %s - save --- ';

  c_pth_UserData                = 'userdata\';
  c_pth_SaveGames               = 'savegames\';
  c_pth_Help                    = 'help\';
  c_pth_Languages               = 'languages\';
  c_pth_RoamingAdd              = 'ich.su_games\';
{$IFDEF NEWPATHS}
  c_pth_Gameplay                = 'gameplay\';
  c_pth_ViewStyles              = 'appearance\';
{$ELSE}
  c_pth_Gameplay                = 'templates\gameplay\';
  c_pth_ViewStyles              = 'templates\appearance\';
{$ENDIF}




  about_Caption                 = 'about'; 
  about_FontName                = 'Tahoma';

  list_button_Ok                : string = 'Ok';
  list_button_Cancel            : string = 'Cancel';
  list_caption                  = '%0s - %1s';

  list_language_Caption         = 'choose language';
  list_language_Title           = 'Choose language:';

  list_language_Exe             = 'broken English, from the exe-file';
  c_English                     = 'English';

  list_workpath_Caption         : string = 'save folder';
  list_workpath_Title           : string = 'The program runs for the first time on the computer. Select where the game data will be located:';
  list_workpath_1               : string = 'current working folder:';
  list_workpath_2               : string = 'the user''s profile folder:';

  location_Work                 = 'working directory';
  location_Roaming              = 'user profile';
  vn_prj_droplocation           = 'droplocation';
  vn_prj_droplanguage           = 'droplanguage';

  list_LngFormat               = '[%s]';

  list_appearance_Caption       : string = 'appearance';
  list_appearance_Title         : string = 'Select the configuration for the visual display of the game:'; // что-то много the !!!
  list_appearance_current       : string = 'such as at the moment';
  list_appearance_button_Cfg    : string = 'open folder...';

  list_gameplay_Caption         : string = 'gameplay';
  list_gameplay_Title           : string = 'Select a configuration to customize the gameplay of the game:'; // !!!
  list_gameplay_current         : string = 'current gameplay';

  list_Metka                    = #1;



  ini_main                      = 'main';
  ini_controls                  = 'controls';
  ini_game                      = 'game';




  msg_AreYouShure               : string = 'are you sure?';
  msg_Confirm                   : string = 'confirmation';


implementation

end.

