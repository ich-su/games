unit pc;

{$I defines.inc}

interface

uses
{$IFDEF PULSE}
  WSL,
{$ELSE}
  Mutex,
{$ENDIF}
  SysUtils, Classes, Graphics, i_classes;

const
{$IFDEF PULSE}
  PCVersion: string = 'ПУЛЬС-Си, версия 2.15';
{$ELSE}
  PCVersion: string = 'Embedded Scripting Language, v2.15';
{$ENDIF}

  var_True = '1';
  var_False = '0';

type
  TErrFunc = procedure(AError: string) of object;

const
  GlobalCompilerErrFunc: TErrFunc = nil;

type
  TVrfFuncObj = function(PtrValue: Pointer): Boolean of object;
  TVrfFunc    = function(PtrValue: Pointer): Boolean;

  VariableType = (vtString, vtInteger, vtFloat, vtBool, vtNatural, vtPercent, vtColor, vtPointer,
    vtVar, vtVoid, vtFunction, vtVarString, vtVarInteger, vtVarFloat, vtVarBool, vtVarNatural,
    vtVarPercent, vtVarColor);

  TToken = record
    ID: Integer;
    Value: Variant;
    Line: Integer;
  end;

  TVar = class
  private
    Name: string;
    Receiver: TObject;
    VType: VariableType;
    IsObject: Boolean;
    Dim: Integer;
  public
    function SetValue(V: Variant; const Index: Integer = -1): Boolean; virtual;
    constructor Create(const S: string);
  end;

  TVariable = class(TVar)
  private
    Value: Variant;
    IsConst: Boolean;
    OnChange: Pointer;
    Values: Pointer;
  public
    function SetValue(V: Variant; const Index: Integer = -1): Boolean; override;
    function GetValue(const Index: Integer = -1): Variant;
    destructor Destroy; override;
  end;

  TFunction = class(TVar)
  private
    Ptr: Pointer;
    Param: array of VariableType;
    ParamCount: Integer;
    Result: VariableType;
  end;

  TLocalFunction = record
    Name: string;
    Pos: Cardinal;
  end;

  TFindInfo = record
    VType: Integer;
    Variable: TVar;
    Index: Integer;
  end;

  TVarList = class(TSortedList)
  protected
    function Compare(V1, V2: Pointer): Integer; override;
  end;

  TVarRegistrator = class(TMutexObject)
  private
    Vars: TVarList;

    function GetVariable(Index: Integer): TVar;
    function GetName(Index: Integer): string;
    function GetValue(Index: Integer): string;
    function GetVType(Index: Integer): VariableType;
    function GetConst(Index: Integer): Boolean;
    function GetCount: Integer;
    function RegisterVariable(VName: string; VType: VariableType; AObject: TObject;
      Ptr: Pointer; ChangeProc: Pointer; AConst: Boolean; IsObject: Boolean; Dim: Integer = -1): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function RegistryString(Name: string; var V: string; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryStringS(Name: string; var V: string; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryInteger(Name: string; var V: Integer; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryIntegerS(Name: string; var V: Integer; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryFloat(Name: string; var V: Double; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryFloatS(Name: string; var V: Double; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryBoolean(Name: string; var V: Boolean; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryBooleanS(Name: string; var V: Boolean; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryNatural(Name: string; var V: Integer; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryNaturalS(Name: string; var V: Integer; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryPercent(Name: string; var V: Double; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryPercentS(Name: string; var V: Double; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryColor(Name: string; var V: TColor; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryColorS(Name: string; var V: TColor; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;

    function RegistryArray(Name: string; VType: VariableType; Dim: Integer = 0): Boolean;

    function RegistryFunction(FName: string; Ptr: Pointer; AObject: TObject; AResult: VariableType; VarArray: array of VariableType): Boolean;
    function RegistryFunctionS(FName: string; Ptr: Pointer; AResult: VariableType; VarArray: array of VariableType): Boolean;
    function RegistryFunctionName(FName: string; Ptr: Pointer): Boolean;
    function RegistryFunctionNameS(FName: string; Ptr: Pointer): Boolean;

    procedure Clear;

    function VTypeToStr(V: VariableType): string;
    function SearchVar(const Name: string; var Index: Integer): Boolean;
    property Variable[Index: Integer]: TVar read GetVariable; default;
    property Name[Index: Integer]: string read GetName;
    property Value[Index: Integer]: string read GetValue;
    property VType[Index: Integer]: VariableType read GetVType;
    property IsConst[Index: Integer]: Boolean read GetConst;
    property Count: Integer read GetCount;
  end;

  TVarLocal = class(TVarRegistrator)
  public
    procedure AddVariable(Name: string; VType: VariableType; Value: Integer = 0;
      IsConst: Boolean = False; Dim: Integer = -1);
  end;

  TCompiler = class(TMutexObject)
  private
    LVars: TVarLocal;
    GVars: TVarRegistrator;
    XVars: TVarLocal;

    LFunctions: array of TLocalFunction;
    nLFuncs: Integer;
    FuncExit: Boolean;

    DSep: Char;
    CallMsg: Boolean;
    MExec: Integer;
    ErrMutex: Integer;
    CurTime: TDateTime;
    Pref: string;

    Script: string;
    SL: Cardinal;
    Fwd: Cardinal;
    TempCode, Cache: array of TToken;
    CL, TCL: Cardinal;
    TCFwd: Cardinal;
    LineNo, ErrLine: Integer;

    HasErr: Boolean;
    ErrExit: Boolean;

    FErrFunc: TErrFunc;

    function GetToken: TToken;
    function FillCache: Boolean;
    function MatchBlock(const n: Integer): Boolean;
    function GetType(const ID: Integer): VariableType;
    function GetLocalFuncValue(Pre, LPre: string; APos, BOfs, EOfs: Cardinal): Variant;
    function GetFuncValue(const Pre: string; BOfs, EOfs: Cardinal): Variant; stdcall;
    function Evaluate(const Pre: string; BOfs, EOfs, Level: Cardinal): Variant;
    function Execute(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function AddFunc(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecDecl(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecIf(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecWhile(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecDo(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecRepeat(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecFor(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecSwitch(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecNew(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecFree(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    function ExecVar(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
    procedure AddTemp(const Token: TToken);
    function GetVar(const Name: string): TVariable;
    procedure SetPointer(const Pre, Name: string; var TCFwd: Cardinal; Run: Boolean; const Index: Integer = -1);
    function SetValue(VName: string; Value: Variant; const Index: Integer = -1; const Line: Integer = 0; const Adr: Boolean = False): Boolean;
    function GetValue(VName: string; const Index: Integer = -1; const Line: Integer = 0; const NA: Boolean = False; const Adr: Boolean = False): Variant;
    function SearchLocalFunc(const Name: string): Integer;
    function FindByName(Pre, Name: string; var FindInfo: TFindInfo): Boolean;
    procedure SetError(EType, Line: Integer; EStr: string);
    function SearchSymbol(const Name: string): Boolean;
    procedure Prepare(const S: TStrings);
    procedure Finalize;
    procedure SetLengthA(AIndex, Dim: Integer);
    function ToStr(const Pre: string; BOfs: Cardinal): string;

    function IsExecuted: Boolean;
    procedure ChangeStatus(S: Boolean);
  public
    MaxTime: Integer;
    LastError: string;

    constructor Create(V: TVarRegistrator; APref: string = '');
    destructor Destroy; override;

    function AddVariable(Name: string; VType: VariableType; Value: Integer = 0;
      IsConst: Boolean = False): Boolean;

    function RegistryString(Name: string; var V: string; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryStringS(Name: string; var V: string; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryInteger(Name: string; var V: Integer; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryIntegerS(Name: string; var V: Integer; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryFloat(Name: string; var V: Double; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryFloatS(Name: string; var V: Double; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryBoolean(Name: string; var V: Boolean; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryBooleanS(Name: string; var V: Boolean; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryNatural(Name: string; var V: Integer; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryNaturalS(Name: string; var V: Integer; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryPercent(Name: string; var V: Double; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryPercentS(Name: string; var V: Double; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;
    function RegistryColor(Name: string; var V: TColor; AObject: TObject = nil; OnChange: TVrfFuncObj = nil; AConst: Boolean = False): Boolean;
    function RegistryColorS(Name: string; var V: TColor; OnChange: TVrfFunc = nil; AConst: Boolean = False): Boolean;

    function RegistryArray(Name: string; VType: VariableType; Dim: Integer): Boolean;

    function RegistryFunction(FName: string; Ptr: Pointer; AObject: TObject;
      AResult: VariableType; VarArray: array of VariableType): Boolean;
    function RegistryFunctionS(FName: string; Ptr: Pointer; AResult: VariableType;
      VarArray: array of VariableType): Boolean;
    function RegistryFunctionName(FName: string; Ptr: Pointer): Boolean;
    function RegistryFunctionNameS(FName: string; Ptr: Pointer): Boolean;

    function Compile(S: TStrings): Boolean;
    function Translate(S: TStrings; const AError: Boolean; const CallMessages: Boolean;
      const AMaxTime: Integer): Boolean;
    function TranslateStr(S: string): Boolean;

    property Executed: Boolean read IsExecuted write ChangeStatus;
    property ErrFunc: TErrFunc read FErrFunc write FErrFunc;
  end;

  function BoolToStr(B: Boolean): string;
  function CompiledStr(const S: string): string;
//  function UnCompiledStr(const S: string): string;
  function Convert(V: Variant; var VOut: Variant; TFrom, TTo: VariableType): Boolean;

const
  TCompilerPTR: Pointer = TCompiler;
  TVarRegistratorPTR: Pointer = TVarRegistrator;

  Errors: array[1..13] of string = (
{$IFDEF LANGENG}
    'syntax error <'#1'>',
    'variable or function already defined <'#1'>',
    'variable or function not defined <'#1'>',
    'unable to set value to variable <'#1'>',
    'wrong parameters count for function <'#1'>',
    'type mismatch <'#1'>',
    'division by zero <'#1'>',
    'wrong var parameter',
    'time elapsed',
    'wrong default parameters description for function <'#1'>',
    'index of array <'#1'> is out of range',
    'uninitialized pointer <'#1'>',
    'exception in function <'#1'>');
{$ELSE}
    'неверный синтаксис <'#1'>',
    'переменная или функция уже определена <'#1'>',
    'переменная или функция не определена <'#1'>',
    'невозможно присвоить значение переменной <'#1'>',
    'неверное число параметров функции <'#1'>',
    'несоответствие типов в выражении <'#1'>',
    'деление на нуль <'#1'>',
    'неверная передача параметра по ссылке',
    'время выполнения истекло',
    'неверное описание параметров по умолчанию в функции <'#1'>',
    'индекс массива <'#1'> вне допустимого диапазона',
    'указатель <'#1'> не инициализирован',
    'исключительная ситуация в функции <'#1'>');
{$ENDIF}

implementation

uses
  Windows, Forms, Variants,
  RxStrUtils, rxVclUtils,
{$IFDEF PCDEBUG} Unit1, {$ENDIF}
{$IFDEF PULSE} Msg, WDB_Strings, {$ENDIF}
  i_str, i_sys;

type
  TCharSet = set of Char;

  TMove = array[0..1] of Integer;

  TKeyword = record
    ID      : Integer;
    Keyword : string;
  end;

  TBlock = record
    VCount  : Integer;
    SCount  : Integer;
    Moves   : array of Integer;
  end;

  TAInteger = array of Integer;
  TABool    = array of Boolean;
  TAColor   = array of TColor;
  TAFloat   = array of Double;
  TAPointer = array of Pointer;

const
  erSyntax          = 1;
  erAlreadyDefined  = 2;
  erVarNotFound     = 3;
  erConstAssigned   = 4;
  erInvalidParams   = 5;
  erInvalidType     = 6;
  erDivisionByZero  = 7;
  erInvalidVar      = 8;
  erTimeElapsed     = 9;
  erInvalidDefParam = 10;
  erOutOfRange      = 11;
  erNilPointer      = 12;
  erException       = 13;

  EQ    = 261; // ==
  NE    = 262; // !=
  GE    = 263; // >=
  LE    = 264; // <=
  _AND  = 265; // &&
  _OR   = 266; // ||

  CINT    = 281;  // Целое число
  CFLOAT  = 282;  // Вещественное число
  CSTRING = 283;  // Строка

  VARNAME = 400;  // Имя переменной, массива или функции

  nKeywords = 21;
  Keywords: array[1..nKeywords] of TKeyword =
  ((ID: 301; Keyword: 'IF'),
   (ID: 302; Keyword: 'WHILE'),
   (ID: 321; Keyword: 'INT'),
   (ID: 322; Keyword: 'FLOAT'),
   (ID: 323; Keyword: 'STRING'),
   (ID: 324; Keyword: 'BOOL'),
   (ID: 329; Keyword: 'VOID'),
   (ID: 307; Keyword: 'FOR'),
   (ID: 325; Keyword: 'NATURAL'),
   (ID: 326; Keyword: 'PERCENT'),
   (ID: 327; Keyword: 'COLOR'),
   (ID: 306; Keyword: 'ELSE'),
   (ID: 303; Keyword: 'DO'),
   (ID: 304; Keyword: 'REPEAT'),
   (ID: 305; Keyword: 'UNTIL'),
   (ID: 308; Keyword: 'EXIT'),
   (ID: 309; Keyword: 'SWITCH'),
   (ID: 310; Keyword: 'DEFAULT'),
   (ID: 311; Keyword: 'NEW'),
   (ID: 312; Keyword: 'FREE'),
   (ID: 328; Keyword: 'POINTER'));

  Firsts: TCharSet = ['=','<','>','!','&','|'];
  Opers: TCharSet = ['+','-','*','/','<','>','\','%','^'];  // 401
  PreExpr: TCharSet = ['-','+','!'];                        // 402

  // Основной блок
  B501: array[0..4, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1, 2, 3, 2, 0),
     (123, 2, 0, 0, 0, 0),  // {
     (502, 5, 3, 0, 3, 0),  // Инструкция
     (59,  5, 0, 4, 0, 0),  // ;
     (125,-1, 5, 5, 5, 0)); // }

  // Инструкция
  B502: array[0..14, 0..2] of Integer =
//    id   1  2
    ((0,   1, 0),
     (503, 2, 0),  // Определение функции
     (504, 2, 0),  // Определение переменной
     (505, 2, 0),  // Присваивание
     (508, 2, 0),  // Функция (вызов)
     (507, 2, 0),  // Переменная (вызов функции без скобок)
     (510, 2, 0),  // IF
     (511, 2, 0),  // WHILE
     (514, 2, 0),  // FOR
     (512, 2, 0),  // REPEAT
     (513, 2, 0),  // DO..WHILE
     (518, 2, 0),  // NEW
     (519, 2, 0),  // FREE
     (517, 2, 0),  // SWITCH
     (308, 2, 0)); // EXIT

  // Определение функции
  B503: array[0..8, 0..8] of Integer =
//    id   1  2  3  4  5  6  7  8
    ((0,   1, 3, 4, 5, 6, 0, 5, 6),
     (506, 2, 0, 0, 0, 0, 0, 0, 0),  // Тип
     (329, 2, 0, 0, 0, 0, 0, 0, 0),  // Тип void
     (400,-1, 3, 0, 0, 0, 0, 0, 0),  // Имя
     (40,  0,-1, 4, 0, 0, 0, 0, 0),  // (
     (41,  0, 0,-1, 5, 0, 0, 5, 0),  // )
     (504, 0, 0, 0, 7, 0, 0, 0, 7),  // Определение переменной
     (520, 0, 0, 0,-1, 6, 0, 0,-1),  // Основной блок c {}
     (59,  0, 0, 0, 0,-1, 0, 8, 0)); // ;

  // Определение переменной
  B504: array[0..5, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1, 2,-3, 4,-5),
     (506, 2, 0, 0, 0, 0),  // Тип
     (507,-1, 3, 0, 0, 0),  // Переменная
     (61,  0,-1, 4, 0, 0),  // =
     (509, 0, 0, 0, 5, 0),  // Выражение
     (44,  0, 0, 2,-1, 2)); // ,

  // Присваивание
  B505: array[0..3, 0..4] of Integer =
//    id   1  2  3  4
    ((0,   1, 2, 3, 0),
     (516, 2, 0, 0, 0),  // Переменная *
     (61, -1, 3, 0, 0),  // =
     (509, 0,-1, 4, 0)); // Выражение

  // Тип
  B506: array[0..8, 0..2] of Integer =
//    id   1  2
    ((0,   1, 0),
     (321, 2, 0),  // INT
     (322, 2, 0),  // FLOAT
     (323, 2, 0),  // STRING
     (324, 2, 0),  // BOOL
     (325, 2, 0),  // NATURAL
     (326, 2, 0),  // PERCENT
     (327, 2, 0),  // COLOR
     (328, 2, 0)); // POINTER

  // Переменная
  B507: array[0..4, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1,-2, 3, 4, 0),
     (400, 2, 0, 0, 0, 0),  // Имя
     (91, -1, 3, 0, 0, 0),  // [
     (509, 0,-1, 4, 0, 0),  // Выражение
     (93,  0, 0, 5, 5, 0)); // ]

  // Функция (вызов)
  B508: array[0..5, 0..6] of Integer =
//    id   1  2  3  4  5  6
    ((0,   1, 2, 3, 3, 4, 0),
     (400, 2, 0, 0, 0, 0, 0),  // Имя
     (40, -1, 3, 0, 0, 0, 0),  // (
     (509, 0,-2, 5, 5, 0, 0),  // Выражение
     (44,  0, 0, 0, 0, 4, 0),  // ,
     (41,  0, 0, 6, 0, 6, 0)); // )

  // Выражение
  B509: array[0..10, 0..4] of Integer =
//    id   1  2  3  4
    ((0,   1,-2, 5, 6),
     (402, 1, 0, 0, 0),  // Унарные операторы +,-,!
     (401, 0, 1, 0, 0),  // Бинарные операторы
     (508, 2,-1, 0, 0),  // Функция
     (40,  3, 0, 0, 0),  // (
     (509, 0, 0, 4, 0),  // Выражение
     (41,  0, 0,-1, 2),  // )
     (281, 2, 0, 0,-1),  // Целая константа
     (282, 2, 0, 0, 0),  // Вещественная константа
     (283, 2, 0, 0, 0),  // Строковая константа
     (515, 2, 0, 0, 0)); // Переменная *@

  // IF
  B510: array[0..6, 0..8] of Integer =
//    id   1  2  3  4  5  6  7  8
    ((0,   1, 2, 3, 4, 5,-6,-5, 0),
     (301, 2, 0, 0, 0, 0, 0, 0, 0),  // IF
     (40, -1, 3, 0, 0, 0, 0, 0, 0),  // (
     (509, 0,-1, 4, 0, 0, 0, 0, 0),  // Выражение
     (41,  0, 0,-1, 5, 0, 0, 0, 0),  // )
     (501, 0, 0, 0,-1, 6, 0, 8, 0),  // Основной блок
     (306, 0, 0, 0, 0,-1, 7,-1, 0)); // ELSE

  // WHILE
  B511: array[0..5, 0..6] of Integer =
//    id   1  2  3  4  5  6
    ((0,   1, 2, 3, 4, 5, 0),
     (302, 2, 0, 0, 0, 0, 0),  // WHILE
     (40, -1, 3, 0, 0, 0, 0),  // (
     (509, 0,-1, 4, 0, 0, 0),  // Выражение
     (41,  0, 0,-1, 5, 0, 0),  // )
     (501, 0, 0, 0,-1, 6, 0)); // Основной блок

  // REPEAT
  B512: array[0..6, 0..7] of Integer =
//    id   1  2  3  4  5  6  7
    ((0,   1, 2, 3, 4, 5, 6, 0),
     (304, 2, 0, 0, 0, 0, 0, 0),  // REPEAT
     (501,-1, 3, 0, 0, 0, 0, 0),  // Основной блок
     (305, 0,-1, 4, 0, 0, 0, 0),  // UNTIL
     (40,  0, 0,-1, 5, 0, 0, 0),  // (
     (509, 0, 0, 0,-1, 6, 0, 0),  // Выражение
     (41,  0, 0, 0, 0,-1, 7, 0)); // )

  // DO..WHILE
  B513: array[0..6, 0..7] of Integer =
//    id   1  2  3  4  5  6  7
    ((0,   1, 2, 3, 4, 5, 6, 0),
     (303, 2, 0, 0, 0, 0, 0, 0),  // DO
     (501,-1, 3, 0, 0, 0, 0, 0),  // Основной блок
     (302, 0,-1, 4, 0, 0, 0, 0),  // WHILE
     (40,  0, 0,-1, 5, 0, 0, 0),  // (
     (509, 0, 0, 0,-1, 6, 0, 0),  // Выражение
     (41,  0, 0, 0, 0,-1, 7, 0)); // )

  // FOR
  B514: array[0..8, 0..10] of Integer =
//    id   1  2  3  4  5  6  7  8  9 10
    ((0,   1, 2, 3, 5, 4, 5, 3, 7, 8, 0),
     (307, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0),  // FOR
     (40, -1, 3, 0, 0, 0, 0, 0, 0, 0, 0),  // (
     (502, 0,-1, 4, 0, 0, 0, 8, 0, 0, 0),  // Инструкция
     (509, 0, 0,-1, 0, 6, 0,-1, 0, 0, 0),  // Выражение
     (59,  0, 0, 0, 5,-1, 7, 0, 0, 0, 0),  // ;
     (505, 0, 0, 0,-1, 0,-1, 0, 0, 0, 0),  // Присваивание
     (41,  0, 0, 0, 0, 0, 0, 0, 9, 0, 0),  // )
     (501, 0, 0, 0, 0, 0, 0, 0,-1,10, 0)); // Основной блок

  // Переменная *@
  B515: array[0..5, 0..6] of Integer =
//    id   1  2  3  4  5  6
    ((0,   1, 0, 1, 1, 1, 5),
     (507, 2, 0, 2, 2, 6, 0),  // Переменная
     (42,  3, 0, 0,-1,-1, 0),  // *
     (64,  4, 0, 0, 0, 0, 0),  // @
     (40, -1, 0, 5, 0, 0, 0),  // (
     (41,  0, 0,-1, 0, 0, 2)); // )

  // Переменная *
  B516: array[0..4, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1, 0, 1, 1, 4),
     (507, 2, 0, 2, 5, 0),  // Переменная
     (42,  3, 0, 0,-1, 0),  // *
     (40, -1, 0, 4, 0, 0),  // (
     (41,  0, 0,-1, 0, 2)); // )

  // SWITCH
  B517: array[0..11, 0..15] of Integer =
//    id   1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
    ((0,   1, 2, 5, 3, 4, 5, 6, 9, 8, 0, 7, 9, 8,11, 5),
     (309, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  // SWITCH
     (40, -1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  // (
     (41 , 0,-1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  // )
     (123, 0, 0, 0,-1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  // {
     (509, 0, 0, 4, 0,-1, 7, 0, 0, 0, 0, 0, 0, 0, 0, 7),  // Выражение
     (44,  0, 0,-1, 0, 0, 0,15, 0, 0, 0, 0, 0, 0, 0,-1),  // ,
     (58,  0, 0, 0, 0, 0, 0, 8, 0, 0, 0,12, 0, 0, 0, 0),  // :
     (59,  0, 0, 0, 0, 0, 0,-1, 0, 6, 0,-1, 0,14, 0, 0),  // ;
     (501, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0,13, 0, 0, 0),  // Основной блок
     (310, 0, 0, 0, 0, 0,11, 0,-1, 0, 0, 0,-1, 0, 0, 0),  // DEFAULT
     (125, 0, 0, 0, 0, 0,10, 0, 0,10, 0, 0, 0,10,10, 0)); // }

  // NEW
  B518: array[0..7, 0..9] of Integer =
//    id   1  2  3  4  5  6  7  8  9
    ((0,   1, 2, 2, 4, 5, 4, 6, 7, 0),
     (311, 2, 0, 0, 0, 0, 0, 0, 0, 0),  // NEW
     (40, -1, 3, 0, 0, 0, 0, 0, 0, 0),  // (
     (507, 0,-1, 4, 0, 0, 0, 0, 0, 0),  // Переменная
     (44,  0, 0,-1, 5, 0, 7, 0, 0, 0),  // ,
     (506, 0, 0, 0,-1, 6, 0, 0, 0, 0),  // Тип
     (509, 0, 0, 0, 0,-1, 0, 8, 0, 0),  // Выражение
     (41,  0, 0, 0, 0, 0, 9,-1, 9, 0)); // )

  // FREE
  B519: array[0..4, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1, 2, 3, 4, 0),
     (312, 2, 0, 0, 0, 0),  // FREE
     (40, -1, 3, 0, 0, 0),  // (
     (507, 0,-1, 4, 0, 0),  // Переменная
     (41,  0, 0,-1, 5, 0)); // )

  // Основной блок с обязательными {}
  B520: array[0..4, 0..5] of Integer =
//    id   1  2  3  4  5
    ((0,   1, 2, 3, 2, 0),
     (123, 2, 0, 0, 0, 0),  // {
     (502,-1, 3, 0, 3, 0),  // Инструкция
     (59,  0, 0, 4, 0, 0),  // ;
     (125, 0, 5, 5, 5, 0)); // }

  nBlocks = 20;
  Blocks: array[1..nBlocks] of TBlock =
    ((VCount: 4; SCount: 6; Moves: @B501),
     (VCount: 14; SCount: 3; Moves: @B502),
     (VCount: 8; SCount: 9; Moves: @B503),
     (VCount: 5; SCount: 6; Moves: @B504),
     (VCount: 3; SCount: 5; Moves: @B505),
     (VCount: 8; SCount: 3; Moves: @B506),
     (VCount: 4; SCount: 6; Moves: @B507),
     (VCount: 5; SCount: 7; Moves: @B508),
     (VCount: 10; SCount: 5; Moves: @B509),
     (VCount: 6; SCount: 9; Moves: @B510),
     (VCount: 5; SCount: 7; Moves: @B511),
     (VCount: 6; SCount: 8; Moves: @B512),
     (VCount: 6; SCount: 8; Moves: @B513),
     (VCount: 8; SCount: 11; Moves: @B514),
     (VCount: 5; SCount: 7; Moves: @B515),
     (VCount: 4; SCount: 6; Moves: @B516),
     (VCount: 11; SCount: 16; Moves: @B517),
     (VCount: 7; SCount: 10; Moves: @B518),
     (VCount: 4; SCount: 6; Moves: @B519),
     (VCount: 4; SCount: 6; Moves: @B520));

  Charsets: array[1..14] of TCharSet =
  (['0'..'9'],                        // 1
   ['1'..'9'],                        // 2
   ['0'..'9','A'..'F','a'..'f'],      // 3
   ['+','-'],                         // 4
   ['X','x'],                         // 5
   ['.'],                             // 6
   [''''],                            // 7
   ['|'],                             // 8
   [#0..#255] - ['|',''''],           // 9
   ['E','e'],                         // 10
   ['0'],                             // 11
   ['|','n',''''],                    // 12
   ['A'..'Z','a'..'z','_'],           // 13 - начало переменной
   ['A'..'Z','a'..'z','_','0'..'9']); // 14 - переменнная без первого символа

  nsToken = 14;
  nmToken = 4;
  mToken: array[1..nsToken, 1..nmToken] of TMove =
  (((2,7),  (6,2),  (6,11), (14,13)), // 1
   ((2,9),  (3,8),  (4,7),  (0,0)),   // 2
   ((2,12), (0,0),  (0,0),  (0,0)),   // 3
   ((0,0),  (0,0),  (0,0),  (0,0)),   // 4
   ((5,1),  (9,6),  (10,10),(0,0)),   // 5
   ((5,1),  (7,5),  (9,6),  (10,10)), // 6
   ((8,3),  (0,0),  (0,0),  (0,0)),   // 7
   ((8,3),  (0,0),  (0,0),  (0,0)),   // 8
   ((11,1), (0,0),  (0,0),  (0,0)),   // 9
   ((12,4), (13,1), (0,0),  (0,0)),   // 10
   ((11,1), (10,10),(0,0),  (0,0)),   // 11
   ((13,1), (0,0),  (0,0),  (0,0)),   // 12
   ((13,1), (0,0),  (0,0),  (0,0)),   // 13
   ((14,14),(0,0),  (0,0),  (0,0)));  // 14

function BoolToStr(B: Boolean): string;
begin
  if B then Result := var_True
  else Result := var_False;
end;

function HexToInt(const s: string; var I: Integer): Boolean;
var
  j, k: Integer;
begin
  Result := True;
  j := 3;
  i := 0;
  k := 0;
  while Result and (j <= Length(s)) do begin
    if not(s[j] in ['0'..'9','a'..'f','A'..'F']) then Result := False
    else begin
      if (s[j] in ['0'..'9']) then k := Ord(s[j]) - Ord('0')
      else if (s[j] in ['a'..'f']) then k := Ord(s[j]) - Ord('a') + 10
      else if (s[j] in ['A'..'F']) then k := Ord(s[j]) - Ord('A') + 10;
      i := (i shl 4) + k;
    end;
    Inc(j);
  end;
end;

function CompareTypes(V1, V2: Variant): Boolean;
  function GetVarType(V: Variant): VariableType;
  begin
    case VarType(V) and VarTypeMask of
      varSmallInt, varInteger, varByte, varDouble, varSingle, varCurrency: Result := vtFloat;
      varBoolean: Result := vtBool;
      else Result := vtString;
    end;
  end;
begin
  Result := GetVarType(V1) = GetVarType(V2);
end;

function CompiledStr(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '''': Result := Result + '|' + S[I];
      #1..#26: Result := Result + '|' + Char(Byte(S[I]) + 64);
      #27..#31: Result := Result + '|' + Char(Byte(S[I]) + Byte('0') - 26);
      #0: Result := Result + '|' + '0';
      else Result := Result + S[I];
    end;
end;

{function UnCompiledStr(const S: string): string;
var
  K: Integer;
begin
  Result := S;
  repeat
    K := Pos('|', Result);
    if (K <> 0) then begin
      Delete(Result, K, 1);
      case UpCase(Result[K]) of
        'A'..'Z': Result[K] := Char(Byte(UpCase(Result[K])) - 64);
        '1'..'5': Result[K] := Char(Byte(UpCase(Result[K])) - Byte('0') + 26);
        '0': Result[K] := #0;
      end;
    end;
  until K = 0;
end;}

function Convert(V: Variant; var VOut: Variant; TFrom, TTo: VariableType): Boolean;
var
  I: Integer;
  D: Double;
  S: string;
begin
  Result := True;
  VOut := V;
  if TFrom = vtVoid then
    case VarType(V) and varTypeMask of
      varSmallInt, varInteger, varByte: TFrom := vtInteger;
      varDouble, varSingle, varCurrency: TFrom := vtFloat;
      varBoolean: TFrom := vtBool;
      else TFrom := vtString;
    end;
  case TFrom of
    vtInteger, vtNatural, vtVarInteger, vtVarNatural:
      if (TTo = vtString) or (TTo = vtVarString) then VOut := IntToStr(V);
    vtFloat, vtPercent, vtVarFloat, vtVarPercent:
      if (TTo = vtString) or (TTo = vtVarString) then VOut := FloatToStrF(Double(V), ffGeneral, 15, 0);
    vtBool, vtVarBool:
      case TTo of
        vtString, vtVarString: VOut := BoolToStr(Boolean(V));
        vtInteger, vtNatural, vtFloat, vtPercent, vtColor, vtVarInteger, vtVarNatural, vtVarFloat, vtVarPercent, vtVarColor: if Boolean(V) then VOut := 1 else VOut := 0;
      end;
    vtColor, vtVarColor:
      if (TTo = vtString) or (TTo = vtVarString) then begin
        S := ColorToString(TColor(V));
        I := Pos('$', S);
        if I <> 0 then begin
          Delete(S, I, 1);
          Insert('0x', S, I);
        end;
        VOut := S;
      end;
    vtString, vtVarString:
      case TTo of
        vtInteger, vtNatural, vtColor, vtVarInteger, vtVarNatural, vtVarColor:
          begin
            S := string(V);
            if (length(S) > 1) and (S[1] = '0') and (S[2] In ['x', 'X']) then begin
              Result := HexToInt(string(V), I);
              if Result then VOut := I;
            end
            else begin
              Result := StrToIntVrf(string(V), I);
              if Result then VOut := I;
            end;
          end;
        vtFloat, vtPercent, vtVarFloat, vtVarPercent:
          begin
            S := string(V);
            if (length(S) > 1) and (S[1] = '0') and (S[2] In ['x', 'X']) then begin
              Result := HexToInt(string(V), I);
              if Result then VOut := I;
            end
            else begin
              Result := StrToDoubleVrf(string(V), D);
              if Result then VOut := D;
            end;
          end;
        vtBool, vtVarBool:
          begin
            Result := True;
            if string(V) = var_True then VOut := True
            else
              if string(V) = var_False then VOut := False
              else Result := False;
          end;
      end;
  end;
end;

constructor TVar.Create(const S: string);
begin
  inherited Create;
  Name := S;
  Dim := -1;
end;

function TVar.SetValue(V: Variant; const Index: Integer = -1): Boolean;
begin
  Result := False;
end;

destructor TVariable.Destroy;
var
  i: Integer;
  ps: ^string;
begin
  if Values <> nil then begin
    if VType = vtString then
      for i := 0 to Dim - 1 do begin
        ps := TAPointer(Values)[i];
        Dispose(ps);
      end;
    FreeMem(Values);
  end;
  inherited;
end;

function TVariable.SetValue(V: Variant; const Index: Integer = -1): Boolean;
var
  VX, VV: Variant;
  P1, P2, P3: Pointer;
  B: Integer;
  FCheck: Boolean;
begin
  Result := not IsConst;
  if Result then begin
    FCheck := False;
    if (OnChange <> nil) then begin
      case VType of
        vtVarString:
          begin
            VX := string(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtString);
            FCheck := Result and (string(Pointer(Integer(Value))^) <> VV);
            if Result then string(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarInteger:
          begin
            VX := Integer(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtInteger);
            FCheck := Result and (Integer(Pointer(Integer(Value))^) <> VV);
            if Result then Integer(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarNatural:
          begin
            VX := Integer(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtNatural);
            Result := Result and (VV >= 0);
            FCheck := Result and (Integer(Pointer(Integer(Value))^) <> VV);
            if Result then Integer(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarFloat:
          begin
            VX := Double(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtFloat);
            FCheck := Result and (Double(Pointer(Integer(Value))^) <> VV);
            if Result then Double(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarPercent:
          begin
            VX := Double(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtPercent);
            Result := Result and (VV >= 0) and (VV <= 1);
            FCheck := Result and (Double(Pointer(Integer(Value))^) <> VV);
            if Result then Double(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarColor:
          begin
            VX := TColor(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtColor);
            FCheck := Result and (TColor(Pointer(Integer(Value))^) <> VV);
            if Result then TColor(Pointer(Integer(Value))^) := VV else Exit;
          end;
        vtVarBool:
          begin
            VX := Integer(Pointer(Integer(Value))^);
            Result := Convert(V, VV, vtVoid, vtBool);
            if VV > 0 then VV := 1;
            FCheck := Result and (Integer(Pointer(Integer(Value))^) <> VV);
            if Result then Integer(Pointer(Integer(Value))^) := VV else Exit;
          end;
      end;

      if not (Result and FCheck) then Exit;
      P1 := Pointer(Integer(Value));
      P3 := OnChange;
      if IsObject then begin
        P2 := P1;
        P1 := Receiver;
      end;
      try
        asm
          MOV   EAX, [P1]
          MOV   EDX, [P2]
          CALL  [P3]
          AND   EAX, $FF
          MOV   [B], EAX
        end;
      except
        Result := False;
        case VType of
          vtVarString: string(Pointer(Integer(Value))^) := VX;
          vtVarInteger, vtVarNatural, vtVarBool: Integer(Pointer(Integer(Value))^) := VX;
          vtVarFloat, vtVarPercent: Double(Pointer(Integer(Value))^) := VX;
          vtVarColor: TColor(Pointer(Integer(Value))^) := VX;
        end;
        Exit;
      end;
      if B = 0 then begin
        case VType of
          vtVarString: string(Pointer(Integer(Value))^) := VX;
          vtVarInteger, vtVarNatural, vtVarBool: Integer(Pointer(Integer(Value))^) := VX;
          vtVarFloat, vtVarPercent: Double(Pointer(Integer(Value))^) := VX;
          vtVarColor: TColor(Pointer(Integer(Value))^) := VX;
        end;
        Result := False;
      end;
    end
    else
      case VType of
        vtVarString:
          begin
            Result := Convert(V, VV, vtVoid, vtString);
            if Result then string(Pointer(Integer(Value))^) := VV;
          end;
        vtVarInteger:
          begin
            Result := Convert(V, VV, vtVoid, vtInteger);
            if Result then Integer(Pointer(Integer(Value))^) := VV;
          end;
        vtVarNatural:
          begin
            Result := Convert(V, VV, vtVoid, vtNatural);
            Result := Result and (Integer(VV) >= 0);
            if Result then Integer(Pointer(Integer(Value))^) := VV;
          end;
        vtNatural:
          begin
            Result := Convert(V, VV, vtVoid, vtNatural);
            Result := Result and (Integer(VV) >= 0);
            if Result then
              if Dim < 0 then Value := Integer(VV)
              else TAInteger(Values)[Index] := VV;
          end;
        vtVarFloat:
          begin
            Result := Convert(V, VV, vtVoid, vtFloat);
            if Result then Double(Pointer(Integer(Value))^) := VV;
          end;
        vtVarPercent:
          begin
            Result := Convert(V, VV, vtVoid, vtPercent);
            Result := Result and (Double(VV) >= 0) and (Double(VV) <= 1);
            if Result then Double(Pointer(Integer(Value))^) := VV;
          end;
        vtPercent:
          begin
            Result := Convert(V, VV, vtVoid, vtPercent);
            Result := Result and (Double(VV) >= 0) and (Double(VV) <= 1);
            if Result then
              if Dim < 0 then Value := Double(VV)
              else TAFloat(Values)[Index] := VV;
          end;
        vtVarColor:
          begin
            Result := Convert(V, VV, vtVoid, vtColor);
            if Result then TColor(Pointer(Integer(Value))^) := VV;
          end;
        vtVarBool:
          begin
            Result := Convert(V, VV, vtVoid, vtBool);
            if Result then Boolean(Pointer(Integer(Value))^) := VV;
          end;
        else begin
          if VType <> vtPointer then Result := Convert(V, VV, vtVoid, VType)
          else Result := Convert(V, VV, vtVoid, TVariable(Values).VType);
          if Result then
            if Dim < 0 then
              if VType <> vtPointer then Value := VV
              else case TVariable(Values).VType of
                vtInteger, vtBool, vtColor, vtFloat, vtString: TVariable(Values).Value := VV;
                vtNatural:
                  begin
                    Result := Result and (Integer(VV) >= 0);
                    if Result then TVariable(Values).Value := Integer(VV);
                  end;
                vtPercent:
                  begin
                    Result := Result and (Double(VV) >= 0) and (Double(VV) <= 1);
                    if Result then TVariable(Values).Value := Double(VV);
                  end;
              end
            else case VType of
              vtInteger: TAInteger(Values)[Index] := VV;
              vtBool: TABool(Values)[Index] := VV;
              vtColor: TAColor(Values)[Index] := VV;
              vtFloat: TAFloat(Values)[Index] := VV;
              vtString: string((TAPointer(Values)[Index])^) := VV;
              vtPointer:
                case TVariable((TAPointer(Values)[Index])).VType of
                  vtInteger, vtBool, vtColor, vtFloat, vtString: TVariable((TAPointer(Values)[Index])).Value := VV;
                  vtNatural:
                    begin
                      Result := Result and (Integer(VV) >= 0);
                      if Result then TVariable((TAPointer(Values)[Index])).Value := Integer(VV);
                    end;
                  vtPercent:
                    begin
                      Result := Result and (Double(VV) >= 0) and (Double(VV) <= 1);
                      if Result then TVariable((TAPointer(Values)[Index])).Value := Double(VV);
                    end;
                end;
            end;
        end;
      end;
  end;
end;

function TVariable.GetValue(const Index: Integer = -1): Variant;
begin
  Result := 0;
  if Dim < 0 then
    case VType of
      vtVarString: Result := string(Pointer(Integer(Value))^);
      vtVarInteger, vtVarNatural: Result := Integer(Pointer(Integer(Value))^);
      vtVarFloat, vtVarPercent: Result := Double(Pointer(Integer(Value))^);
      vtVarColor: Result := TColor(Pointer(Integer(Value))^);
      vtVarBool: Result := Boolean(Pointer(Integer(Value))^);
      vtString: Result := string(Value);
      vtInteger, vtNatural: Result := Integer(Value);
      vtFloat, vtPercent: Result := Double(Value);
      vtColor: Result := TColor(Value);
      vtBool: Result := Boolean(Value);
      vtPointer:
        case TVariable(Values).VType of
          vtString: Result := string(TVariable(Values).Value);
          vtInteger, vtNatural: Result := Integer(TVariable(Values).Value);
          vtFloat, vtPercent: Result := Double(TVariable(Values).Value);
          vtColor: Result := TColor(TVariable(Values).Value);
          vtBool: Result := Boolean(TVariable(Values).Value);
        end
    end
  else case VType of
    vtInteger, vtNatural: Result := TAInteger(Values)[Index];
    vtColor: Result := TAColor(Values)[Index];
    vtBool: Result := TABool(Values)[Index];
    vtFloat, vtPercent: Result := TAFloat(Values)[Index];
    vtString: Result := string((TAPointer(Values)[Index])^);
    vtPointer:
      case TVariable((TAPointer(Values)[Index])).VType of
        vtString: Result := string(TVariable((TAPointer(Values)[Index])).Value);
        vtInteger, vtNatural: Result := Integer(TVariable((TAPointer(Values)[Index])).Value);
        vtFloat, vtPercent: Result := Double(TVariable((TAPointer(Values)[Index])).Value);
        vtColor: Result := TColor(TVariable((TAPointer(Values)[Index])).Value);
        vtBool: Result := Boolean(TVariable((TAPointer(Values)[Index])).Value);
      end;
  end;
end;

function TVarList.Compare(V1, V2: Pointer): Integer;
begin
{$IFDEF PULSE}
  Result := StrCompareExtW(PChar(TVar(V1).Name), PChar(TVar(V2).Name), 0, False);
{$ELSE}
  Result := CompareStrFlags2(PChar(TVar(V1).Name), PChar(TVar(V2).Name), False);
{$ENDIF}
end;

constructor TVarRegistrator.Create;
begin
  inherited Create;
  Vars := TVarList.Create;
end;

destructor TVarRegistrator.Destroy;
begin
  Vars.Free;
  inherited Destroy;
end;

function TVarRegistrator.GetName(Index: Integer): string;
begin
  Result := TVar(Vars[Index]).Name;
end;

function TVarRegistrator.GetValue(Index: Integer): string;
var
  V: TVar;
  VX, V2: Variant;
begin
  V := TVar(Vars[Index]);
  Result := '';
  if (V.VType <> vtFunction) then
    begin
      VX := TVariable(V).GetValue;
      if Convert(VX, V2, V.VType, vtString) then Result := V2;
    end;
end;

function TVarRegistrator.GetVType(Index: Integer): VariableType;
begin
  Result := TVar(Vars[Index]).VType;
  case Result of
    vtVarString: Result := vtString;
    vtVarInteger: Result := vtInteger;
    vtVarFloat: Result := vtFloat;
    vtVarNatural: Result := vtNatural;
    vtVarPercent: Result := vtPercent;
    vtVarColor: Result := vtColor;
    vtVarBool: Result := vtBool;
  end;
end;

function TVarRegistrator.VTypeToStr(V: VariableType): string;
begin
  case V of
    vtString, vtVarString: Result := 'string';
    vtInteger, vtVarInteger: Result := 'integer';
    vtFloat, vtVarFloat: Result := 'float';
    vtNatural, vtVarNatural: Result := 'natural';
    vtPercent, vtVarPercent: Result := 'percent';
    vtColor, vtVarColor: Result := 'color';
    vtBool, vtVarBool: Result := 'bool';
    vtPointer: Result := 'pointer';
    vtFunction: Result := 'function';
    vtVoid: Result := 'void';
    else Result := '';
  end;
end;

function TVarRegistrator.GetConst(Index: Integer): Boolean;
begin
  if TVar(Vars[Index]) is TVariable then
    Result := TVariable(Vars[Index]).IsConst
  else Result := False;
end;

function TVarRegistrator.GetCount: Integer;
begin
  Result := Vars.Count;
end;

function TVarRegistrator.RegisterVariable(VName: string; VType: VariableType;
  AObject: TObject; Ptr: Pointer; ChangeProc: Pointer; AConst: Boolean;
  IsObject: Boolean; Dim: Integer = -1): Boolean;
var
  I: Integer;
  V: TVariable;
begin
  Result := not SearchVar(VName, I);
  if Result then begin
    V := TVariable.Create(VName);
    V.VType := VType;
    if Dim < 0 then begin
      V.Value := Integer(Ptr);
      V.OnChange := ChangeProc;
      V.Receiver := AObject;
      V.IsConst := AConst;
      V.IsObject := IsObject;
    end
    else V.Dim := Dim;
    Vars.AddSorted(V);
  end;
end;

function TVarRegistrator.RegistryString;
begin
  Result := RegisterVariable(Name, vtVarString, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryStringS;
begin
  Result := RegisterVariable(Name, vtVarString, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryInteger;
begin
  Result := RegisterVariable(Name, vtVarInteger, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryIntegerS;
begin
  Result := RegisterVariable(Name, vtVarInteger, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryFloat;
begin
  Result := RegisterVariable(Name, vtVarFloat, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryFloatS;
begin
  Result := RegisterVariable(Name, vtVarFloat, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryBoolean;
begin
  Result := RegisterVariable(Name, vtVarBool, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryBooleanS;
begin
  Result := RegisterVariable(Name, vtVarBool, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryNatural;
begin
  Result := RegisterVariable(Name, vtVarNatural, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryNaturalS;
begin
  Result := RegisterVariable(Name, vtVarNatural, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryPercent;
begin
  Result := RegisterVariable(Name, vtVarPercent, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryPercentS;
begin
  Result := RegisterVariable(Name, vtVarPercent, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryColor;
begin
  Result := RegisterVariable(Name, vtVarColor, AObject, @V, @OnChange, AConst, True);
end;

function TVarRegistrator.RegistryColorS;
begin
  Result := RegisterVariable(Name, vtVarColor, nil, @V, @OnChange, AConst, False);
end;

function TVarRegistrator.RegistryArray(Name: string; VType: VariableType; Dim: Integer = 0): Boolean;
begin
  Result := RegisterVariable(Name, VType, nil, nil, nil, False, False, Dim);
end;

function TVarRegistrator.RegistryFunction(FName: string; Ptr: Pointer; AObject: TObject;
  AResult: VariableType; VarArray: array of VariableType): Boolean;
var
  I: Integer;
  F: TFunction;
begin
  Result := not SearchVar(FName, I);
  if Result then begin
    F := TFunction.Create(FName);
    F.VType := vtFunction;
    F.Ptr := Ptr;
    F.Result := AResult;
    F.Receiver := AObject;
    F.IsObject := True;
    SetLength(F.Param, 1 - Low(VarArray) + High(VarArray));
    for I := Low(VarArray) to High(VarArray) do begin
      F.Param[I - Low(VarArray)] := VarArray[I];
    end;
    F.ParamCount := High(VarArray) - Low(VarArray) + 1;
    Vars.AddSorted(F);
  end;
end;

function TVarRegistrator.RegistryFunctionName(FName: string;
  Ptr: Pointer): Boolean;
var
  i: Integer;
  F: TFunction;
begin
  Result := not SearchVar(FName, i);
  if Result then begin
    F := TFunction.Create(FName);
    F.VType := vtFunction;
    F.Ptr := Ptr;
    F.Result := vtVoid;
    F.Receiver := nil;
    F.IsObject := True;
    F.ParamCount := -1;
    Vars.AddSorted(F);
  end;
end;

function TVarRegistrator.RegistryFunctionNameS(FName: string;
  Ptr: Pointer): Boolean;
var
  i: Integer;
  F: TFunction;
begin
  Result := not SearchVar(FName, i);
  if Result then begin
    F := TFunction.Create(FName);
    F.VType := vtFunction;
    F.Ptr := Ptr;
    F.Result := vtVoid;
    F.Receiver := nil;
    F.IsObject := False;
    F.ParamCount := -1;
    Vars.AddSorted(F);
  end;
end;

function TVarRegistrator.RegistryFunctionS(FName: string; Ptr: Pointer; AResult: VariableType;
  VarArray: array of VariableType): Boolean;
var
  I: Integer;
  F: TFunction;
begin
  Result := not SearchVar(FName, I);
  if Result then begin
    F := TFunction.Create(FName);
    F.VType := vtFunction;
    F.Ptr := Ptr;
    F.Result := AResult;
    F.Receiver := nil;
    F.IsObject := False;
    SetLength(F.Param, 1 - Low(VarArray) + High(VarArray));
    for I := Low(VarArray) to High(VarArray) do begin
      F.Param[I - Low(VarArray)] := VarArray[I];
    end;
    F.ParamCount := High(VarArray) - Low(VarArray) + 1;
    Vars.AddSorted(F);
  end;
end;

procedure TVarRegistrator.Clear;
begin
  Vars.Clear;
end;

procedure TVarLocal.AddVariable(Name: string; VType: VariableType; Value: Integer = 0;
  IsConst: Boolean = False; Dim: Integer = -1);
var
  V: TVariable;
  i: Integer;
  Ps: ^string;
begin
  V := TVariable.Create(Name);
  V.VType := VType;
  if Dim < 0 then begin
    V.IsConst := IsConst;
    if VType = vtString then V.Value := ''
    else V.Value := Value;
  end
  else begin
    V.Dim := Dim;
    case VType of
      vtInteger, vtNatural:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(Integer));
          for i := 0 to V.Dim - 1 do TAInteger(V.Values)[i] := 0;
        end;
      vtPointer:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(Pointer));
          for i := 0 to V.Dim - 1 do TAPointer(V.Values)[i] := nil;
        end;
      vtColor:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(TColor));
          for i := 0 to V.Dim - 1 do TAColor(V.Values)[i] := clWhite;
        end;
      vtBool:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(Boolean));
          for i := 0 to V.Dim - 1 do TABool(V.Values)[i] := False;
        end;
      vtFloat, vtPercent:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(Double));
          for i := 0 to V.Dim - 1 do TAFloat(V.Values)[i] := 0;
        end;
      vtString:
        begin
          V.Values := AllocMem(V.Dim * SizeOf(Pointer));
          for i := 0 to V.Dim - 1 do begin
            New(Ps);
            Ps^ := '';
            TAPointer(V.Values)[i] := Ps;
          end;
        end;
    end;
  end;
  Vars.AddSorted(V);
end;

function TVarRegistrator.GetVariable(Index: Integer): TVar;
begin
  Result := Vars[Index];
end;

function TVarRegistrator.SearchVar(const Name: string; var Index: Integer): Boolean;
var
  F: TVar;
begin
  F := TVar.Create(Name);
  try
    Result := Vars.FindSorted(F, Index);
  finally
    F.Free;
  end;
end;

constructor TCompiler.Create(V: TVarRegistrator; APref: string = '');
begin
  inherited Create;
  LVars := TVarLocal.Create;
  XVars := TVarLocal.Create;
  GVars := V;
  ErrMutex := CreateMutex(nil, False, nil);
  MExec := CreateMutex(nil, False, nil);
  Pref := APref;

  XVars.AddVariable('fsBold', vtInteger, 1, True);
  XVars.AddVariable('fsItalic', vtInteger, 2, True);
  XVars.AddVariable('fsUnderline', vtInteger, 4, True);
  XVars.AddVariable('fsStrikeout', vtInteger, 8, True);

  XVars.AddVariable('clInfoBk', vtColor, clInfoBk, True);
  XVars.AddVariable('clNone', vtColor, clNone, True);
  XVars.AddVariable('clCream', vtColor, clCream, True);
  XVars.AddVariable('clMoneyGreen', vtColor, clMoneyGreen, True);
  XVars.AddVariable('clSkyBlue', vtColor, clSkyBlue, True);
  XVars.AddVariable('clHotLight', vtColor, clHotLight, True);
  XVars.AddVariable('clMedGray', vtColor, clMedGray, True);
  XVars.AddVariable('clBlack', vtColor, clBlack, True);
  XVars.AddVariable('clMaroon', vtColor, clMaroon, True);
  XVars.AddVariable('clGreen', vtColor, clGreen, True);
  XVars.AddVariable('clOlive', vtColor, clOlive, True);
  XVars.AddVariable('clNavy', vtColor, clNavy, True);
  XVars.AddVariable('clPurple', vtColor, clPurple, True);
  XVars.AddVariable('clTeal', vtColor, clTeal, True);
  XVars.AddVariable('clGray', vtColor, clGray, True);
  XVars.AddVariable('clSilver', vtColor, clSilver, True);
  XVars.AddVariable('clRed', vtColor, clRed, True);
  XVars.AddVariable('clLime', vtColor, clLime, True);
  XVars.AddVariable('clYellow', vtColor, clYellow, True);
  XVars.AddVariable('clBlue', vtColor, clBlue, True);
  XVars.AddVariable('clFuchsia', vtColor, clFuchsia, True);
  XVars.AddVariable('clAqua', vtColor, clAqua, True);
  XVars.AddVariable('clWhite', vtColor, clWhite, True);
  XVars.AddVariable('clScrollBar', vtColor, clScrollBar, True);
  XVars.AddVariable('clBackground', vtColor, clBackground, True);
  XVars.AddVariable('clActiveCaption', vtColor, clActiveCaption, True);
  XVars.AddVariable('clInactiveCaption', vtColor, clInactiveCaption, True);
  XVars.AddVariable('clMenu', vtColor, clMenu, True);
  XVars.AddVariable('clWindow', vtColor, clWindow, True);
  XVars.AddVariable('clWindowFrame', vtColor, clWindowFrame, True);
  XVars.AddVariable('clMenuText', vtColor, clMenuText, True);
  XVars.AddVariable('clWindowText', vtColor, clWindowText, True);
  XVars.AddVariable('clCaptionText', vtColor, clCaptionText, True);
  XVars.AddVariable('clActiveBorder', vtColor, clActiveBorder, True);
  XVars.AddVariable('clInactiveBorder', vtColor, clInactiveBorder, True);
  XVars.AddVariable('clAppWorkSpace', vtColor, clAppWorkSpace, True);
  XVars.AddVariable('clHighlight', vtColor, clHighlight, True);
  XVars.AddVariable('clHighlightText', vtColor, clHighlightText, True);
  XVars.AddVariable('clBtnFace', vtColor, clBtnFace, True);
  XVars.AddVariable('clBtnHighlight', vtColor, clBtnHighlight, True);
  XVars.AddVariable('clBtnShadow', vtColor, clBtnShadow, True);
  XVars.AddVariable('clBtnText', vtColor, clBtnText, True);
  XVars.AddVariable('clGrayText', vtColor, clGrayText, True);
  XVars.AddVariable('clInactiveCaptionText', vtColor, clInactiveCaptionText, True);
  XVars.AddVariable('cl3DDkShadow', vtColor, cl3DDkShadow, True);
  XVars.AddVariable('cl3DLight', vtColor, cl3DLight, True);
  XVars.AddVariable('clInfoText', vtColor, clInfoText, True);
  XVars.AddVariable('clGradientActiveCaption', vtColor, clGradientActiveCaption, True);
  XVars.AddVariable('clGradientInactiveCaption', vtColor, clGradientInactiveCaption, True);
  XVars.AddVariable('clMenuHighlight', vtColor, clMenuHighlight, True);
  XVars.AddVariable('clMenuBar', vtColor, clMenuBar, True);

  RegistryFunctionS('stop', nil, vtVoid, []);
  RegistryFunctionS('ToStr', nil, vtVoid, []);
  RegistryFunction('SetLength', @TCompiler.SetLengthA, Self, vtVoid, [vtInteger, vtInteger]);
end;

destructor TCompiler.Destroy;
begin
  LVars.Free;
//  XVars.Clear;
  XVars.Free;
  CloseHandle(MExec);
  CloseHandle(ErrMutex);
//  SetLength(TempCode, 0);
//  SetLength(Cache, 0);
  inherited;
end;

function TCompiler.GetFuncValue(const Pre: string; BOfs, EOfs: Cardinal): Variant; stdcall;
var
  X3, X, I, J, K: Integer;
  V, V2: Variant;
  Params: array of Pointer;
  P3: array[0..2] of Pointer;
  F: TFunction;
  DDa: Double;
  S: array of string;
  SC: Integer;
  XX, XL: Integer;
  SResult: string;
  PT: Pointer;
  PVar: TVariable;
  FName, N: string;
type
  DArr = array[0..1] of Pointer;
begin
  Result := 0;
  if HasErr then Exit;
  if Pre <> '' then FName := Pre + '.' else FName := '';
  N := string(TempCode[BOfs].Value);
  repeat
    for I := nLFuncs -1 downto 0 do
{$IFDEF PULSE}
      if StrCompareExtW(PChar(LFunctions[I].Name), PChar(FName + N), 0, False) = 0 then begin
{$ELSE}
      if CompareStrFlags2(PChar(LFunctions[I].Name), PChar(FName + N), False) = 0 then begin
{$ENDIF}
        if Copy(Pre, Length(Pre) - Length(N) + 1, Length(N)) = N then
          Result := GetLocalFuncValue(Pre, Pre, LFunctions[I].Pos, BOfs, EOfs)
        else begin
          if FName <> '' then Delete(FName, Length(FName), 1);
          Result := GetLocalFuncValue(Pre, FName, LFunctions[I].Pos, BOfs, EOfs);
        end;
        Exit;
      end;
    i := Length(FName) - 1;
    while (i > 0) and (FName[i] <> '.') do Dec(i);
    if i = 0 then FName := '' else Delete(FName, i + 1, Length(FName) - i);
  until i < 0;

  F := nil;
  if GVars.SearchVar(TempCode[BOfs].Value, I) then
    if GVars[I] is TFunction then F := TFunction(GVars[I]);
  if XVars.SearchVar(TempCode[BOfs].Value, I) then
    if XVars[I] is TFunction then F := TFunction(XVars[I]);
  if F = nil then begin
    SetError(erVarNotFound, TempCode[BOfs].Line, TempCode[BOfs].Value);
    Exit;
  end;
  if F.Name = 'stop' then begin
    HasErr := True;
    Exit;
  end;
  if F.Name = 'ToStr' then begin
    Result := ToStr(Pre, Bofs);
    Exit;
  end;

  SC := 0;
  X3 := 0;

  XL := F.ParamCount;
  if XL = -1 then begin    // Вызов функции по имени
    J := BOfs + 2;
    if J >= Integer(EOfs) then begin
      SetLength(S, 1);
      S[0] := F.Name;
      PT := S;
      P3[0] := Pointer(Pointer(Integer(PT))^);
    end
    else begin
      SetError(erInvalidParams, TempCode[j].Line, F.Name);
      Exit;
    end;
  end
  else begin
    for XX := 0 to F.ParamCount - 1 do begin
      if F.Param[XX] = vtFloat then Inc(XL);
      if F.Param[XX] = vtString then Inc(SC);
    end;
    SetLength(S, SC);
    SetLength(Params, XL + 1);

    X := 0;
    X3 := 0;
    SC := 0;

    ErrLine := TempCode[BOfs].Line;
    J := BOfs + 2;
    XX := 0;
    while X + X3 < {F.ParamCount} XL do begin
      if J >= Integer(EOfs) then begin
        V := 0;
        if F.Param[XX] in [vtVarInteger, vtVarFloat, vtVarNatural, vtVarColor, vtVarBool, vtVarPercent, vtVarString] then
          begin
            SetError(erInvalidVar, TempCode[J].Line, F.Name);
            Exit;
          end;
        if F.Param[XX] = vtString then V := '';
      end
      else begin
        K := TempCode[J].Value;
        V := Evaluate(Pre, J + 1, J + K, 1);
        if HasErr then Exit;
      end;
      case F.Param[XX] of
        vtVarInteger, vtVarFloat, vtVarNatural, vtVarColor, vtVarBool, vtVarPercent, vtVarString:
          begin
            if TempCode[J].ID <> VARNAME then begin
              SetError(erInvalidVar, TempCode[J + 1].Line, '');
              Exit;
            end;
            PVar := GetVar(Pre + TempCode[J].Value);
            if (PVar = nil) or (PVar.IsConst) or (PVar.VType <> F.Param[XX]) then begin
              SetError(erInvalidVar, TempCode[J + 1].Line, PVar.Name);
              Exit;
            end;
            if X3 < 3 then begin
              P3[X3] := Pointer(Integer(PVar.Value));
              Inc(X3);
            end
            else begin
              Params[X] := Pointer(Integer(PVar.Value));
              Inc(X);
            end;
          end;
        vtInteger, vtPointer, vtNatural, vtColor:
          begin
            if not Convert(V, V2, vtVoid, vtInteger) then begin
              SetError(erInvalidType, TempCode[J + 1].Line, '');
              Exit;
            end;
            if X3 < 3 then begin
              P3[X3] := Pointer(Integer(V));
              Inc(X3);
            end
            else begin
              Params[X] := Pointer(Integer(V));
              Inc(X);
            end;
          end;
        vtBool:
          begin
            if not Convert(V, V2, vtVoid, vtBool) then begin
              SetError(erInvalidType, TempCode[J + 1].Line, '');
              Exit;
            end;
            if X3 < 3 then begin
              P3[X3] := Pointer(Boolean(V));
              Inc(X3);
            end
            else begin
              Params[X] := Pointer(Boolean(V));
              Inc(X);
            end;
          end;
        vtString:
          begin
            Convert(V, V2, vtVoid, vtString);
            V := V2;
            if X3 < 3 then begin
              S[SC] := string(V);
              PT := S;
              P3[X3] := Pointer(Pointer(Integer(PT) + SC * 4)^);
              Inc(SC);
              Inc(X3);
            end
            else begin
              S[SC] := string(V);
              PT := S;
              Params[X] := Pointer(Pointer(Integer(PT) + SC * 4)^);
              Inc(SC);
              Inc(X);
            end;
          end;
        vtFloat, vtPercent:
          begin
            if not Convert(V, V2, vtVoid, vtFloat) then begin
              SetError(erInvalidType, TempCode[J + 1].Line, '');
              Exit;
            end;
            DDa := V;
            Params[X] := DArr(DDa)[1];
            Params[X + 1] := DArr(DDa)[0];
            Inc(X, 2);
          end;
      end;
      Inc(J, K + 2);
      Inc(XX);
    end;
  end;

  if F.IsObject then begin
    if X3 < 3 then begin
      P3[2] := P3[1];
      P3[1] := P3[0];
      P3[0] := F.Receiver;
      Inc(X3);
    end
    else begin
      Move(Params[0], Params[1], Sizeof(Pointer) * X);
      Inc(X);
      Params[0] := P3[2];
      P3[2] := P3[1];
      P3[1] := P3[0];
      P3[0] := F.Receiver;
    end;
  end;
  if F.Result = vtString then
    if X3 < 3 then P3[X3] := @SResult
    else begin
      Params[X] := @SResult;
      Inc(X);
    end;

  try
    for J := 1 to X do begin
      K := Integer(Params[J - 1]);
      asm
        PUSH   [K]
      end;
    end;
    X := Integer(F.Ptr);
    asm
      MOV  EAX, [DWORD PTR P3]
      MOV  EDX, [DWORD PTR P3 + 4]
      MOV  ECX, [DWORD PTR P3 + 8]
      CALL [X]
      MOV  [XX], EAX
    end;
  except
    SetError(erException, TempCode[BOfs].Line, N);
    Exit;
  end;
  case F.Result of
    vtInteger, vtPointer, vtNatural, vtColor: Result := XX;
    vtBool: Result := Boolean(XX and $FF);
    vtFloat, vtPercent:
      begin
        asm
          DB  $DD, $1D
          DD  OFFSET DDa
        end;
        Result := DDa;
      end;
    vtString:
      Result := SResult;
    else Result := 0;
  end;
end;

function TCompiler.GetToken: TToken;
var
  CurState, i, h: Integer;
  s: string;
  Flag: Boolean;
begin
  Result.ID := 0;
  Result.Value := 0;

  // Пропуск комментариев, пробелов, переводов строки
  while Fwd < SL do begin
    if Script[Fwd] = #13 then Inc(LineNo);
    if Script[Fwd] in [' ', #9, #10, #13] then //Nothing
    else if (Script[Fwd] = '/') and (Script[Fwd + 1] = '/') then begin
      repeat Inc(Fwd); until (Fwd > SL) or (Script[Fwd] = #13);
      if Fwd < SL then Inc(LineNo);
    end
    else if (Script[Fwd] = '/') and (Script[Fwd + 1] = '*') then begin
      repeat
        Inc(Fwd);
        if Script[Fwd] = #13 then Inc(LineNo);
      until (Fwd > SL) or ((Script[Fwd] = '*') and (Script[Fwd + 1] = '/'));
      Inc(Fwd);
    end
    else Break;
    Inc(Fwd);
  end;
  if Fwd > SL then Exit;

  s := '';
  CurState := 1;
  repeat
    s := s + Script[Fwd];
    Flag := True;
    for i := 1 to nmToken do
      if mToken[CurState,i][0] <> 0 then
        if Script[Fwd] in Charsets[mToken[CurState,i][1]] then begin
          if CurState = 3 then begin
            SetLength(s, Length(s) - 2);
            case Script[Fwd] of
              '''','|': s := s + Script[Fwd];
              'n': s := s + #10#13;
            end;
          end
          else if (CurState = 2) and (Script[Fwd] in [#10,#13]) then Break;
          CurState := mToken[CurState,i][0];
          Flag := False;
          Break;
        end;
    Inc(Fwd);
  until Flag or (Fwd > SL);
  if Flag and (Length(s) > 1) then begin
    SetLength(s, Length(s) - 1);
    Dec(Fwd);
  end;

  Result.Line := LineNo;
  case CurState of
    1:  begin  // Какой-то символ
          if (Fwd <= SL) and (s[1] in Firsts) then begin
            s := s + Script[Fwd];
            Inc(Fwd);
            if s = '==' then Result.ID := EQ
            else if s = '<=' then Result.ID := LE
            else if s = '>=' then Result.ID := GE
            else if s = '!=' then Result.ID := NE
            else if s = '&&' then Result.ID := _AND
            else if s = '||' then Result.ID := _OR
            else begin
              Result.ID := Ord(s[1]);
              Dec(Fwd);
            end;
          end
          else Result.ID := Ord(s[1]);
        end;
    4:  begin // Строковая константа
          Result.ID := CSTRING;
          Result.Value := Copy(s, 2, Length(s) - 2);
        end;
    5,6:  begin // Целое число
            Result.ID := CINT;
            try
              Result.Value := StrToInt(s);
            except
              SetError(erSyntax, LineNo, '');
            end;
          end;
    8:  begin // Шестнадцатеричное
          Result.ID := CINT;
          if not HexToInt(s, h) then
            SetError(erSyntax, LineNo, '');
          Result.Value := h;
        end;
    11,13:  begin // Вещественное
              Result.ID := CFLOAT;
              try
                Result.Value := StrToFloat(s);
              except
                SetError(erSyntax, LineNo, '');
              end;
            end;
    14: begin // Имя переменной или функции
          for i := 1 to nKeywords do
{$IFDEF PULSE}
            if StrCompareExtW(PChar(Keywords[i].Keyword), PChar(s), 0, False) = 0 then begin
{$ELSE}
            if CompareStrFlags2(PChar(Keywords[i].Keyword), PChar(s), False) = 0 then begin
{$ENDIF}
              Result.ID := Keywords[i].ID;
              Exit;
            end;
          Result.ID := VARNAME;
          Result.Value := s;
        end;
  end;
end;

function TCompiler.FillCache: Boolean;
var
  i: Cardinal;
begin
  Result := False;
  SetLength(Cache, 100);
  CL := 100;
  i := 0;
  while Fwd <= SL do begin
    Cache[i] := GetToken;
    if HasErr then Exit;
    Inc(i);
    if i = CL then begin
      Inc(CL, 100);
      SetLength(Cache, CL);
    end;
  end;
  CL := i + 1;
  Fwd := 0;
  Result := True;
end;

function TCompiler.MatchBlock(const n: Integer): Boolean;
var
  CurState, i, j, id, t, TempFwd: Integer;
  Token: TToken;
  Flag: Boolean;
begin
  Result := False;
  CurState := 1;
  id := 0; TempFwd := 0;
  with Blocks[n] do begin
    repeat
      Flag := False;
      for i := Abs(Moves[CurState]) to Blocks[n].VCount do begin
        if i = 0 then Break;
        t := Fwd;
        j := Moves[i * SCount + CurState];
        if j > 0 then begin
          id := Moves[i * SCount];
          if id <= VARNAME then begin
            Token := Cache[Fwd];
            Inc(Fwd);
            Flag := id = Token.ID;
          end
          else if id = 401 then begin
            Token := Cache[Fwd];
            Inc(Fwd);
            Flag := (Token.ID < 256) and (Char(Token.ID) in Opers)
              or (Token.ID = EQ)
              or (Token.ID = NE)
              or (Token.ID = LE)
              or (Token.ID = GE)
              or (Token.ID = _AND)
              or (Token.ID = _OR);
          end
          else if id = 402 then begin
            Token := Cache[Fwd];
            Inc(Fwd);
            Flag := (Token.ID < 256) and (Char(Token.ID) in PreExpr);
          end
          else begin
            TempFwd := TCFwd;
            if id = 509 then Inc(TCFwd, 1);
            Flag := MatchBlock(id - 500);
            if not Flag then TCFwd := TempFwd;
          end;
        end
        else if j < 0 then Break;
        if Flag then begin
          if id < 500 then AddTemp(Token)
          else if id = 509 then begin
            TempCode[TempFwd].ID := 1000;
            TempCode[TempFwd].Value := Integer(TCFwd) - TempFwd - 1;
            TempCode[TempFwd].Line := LineNo;
          end;
          CurState := j;
          Break;
        end
        else begin
          Fwd := t;
          if Cache[Fwd].Line > ErrLine then ErrLine := Cache[Fwd].Line;
        end;
      end;
    until not Flag;
    if Moves[CurState] <= 0 then Result := True;
  end;
end;

function TCompiler.GetType(const ID: Integer): VariableType;
begin
  case ID of
    321: Result := vtInteger;
    322: Result := vtFloat;
    323: Result := vtString;
    324: Result := vtBool;
    325: Result := vtNatural;
    326: Result := vtPercent;
    327: Result := vtColor;
    328: Result := vtPointer;
    else Result := vtVoid;
  end;
end;

function TCompiler.GetLocalFuncValue(Pre, LPre: string; APos, BOfs, EOfs: Cardinal): Variant;
var
  i, j: Cardinal;
  k: Integer;
  V: Variant;
  FName, VName, t: string;
  vt, rvt: VariableType;
  EndParams, NeedDefault, Tmp: Boolean;
begin
  Result := 0;
  FName := TempCode[APos + 1].Value;
  if LPre <> '' then FName := LPre + '.' + FName;
  rvt := GetType(TempCode[APos].ID);
  if rvt <> vtVoid then AddVariable(FName + '.RESULT', rvt);
  i := BOfs + 1;
  j := APos + 3;
  if TempCode[i].ID = 40 then begin
    Inc(i);
    NeedDefault := False;
    if TempCode[j].ID = 41 then Inc(i);
  end
  else begin
    Dec(i);
    NeedDefault := True;
  end;
  while TempCode[j].ID <> 41 do begin
    if TempCode[j].ID = 59 then Inc(j);
    vt := GetType(TempCode[j].ID);
    EndParams := (TempCode[i].ID = 41) or (i = BOfs);
    if EndParams and (i <> BOfs) then Inc(i);
    repeat
      Inc(j, 2);
      VName := FName + '.' + TempCode[j - 1].Value;
      if (not EndParams) and (TempCode[i - 1].ID = 41) then EndParams := True;
      if EndParams then
        if TempCode[j].ID <> 61 then begin
          SetError(erInvalidParams, TempCode[j].Line, FName);
          Exit;
        end
        else begin
          Inc(j);
          k := TempCode[j].Value;
          V := Evaluate(Pre, j + 1, j + Cardinal(k), 1);
          AddVariable(VName, vt);
          SetValue(VName, V);
          Inc(j, k + 1);
        end
      else begin
        if NeedDefault and (TempCode[j].ID <> 61) then begin
          SetError(erInvalidDefParam, TempCode[j].Line, FName);
          Exit;
        end;
        k := TempCode[i].Value;
        V := Evaluate(Pre, i + 1, i + Cardinal(k), 1);
        AddVariable(VName, vt);
        SetValue(VName, V);
        Inc(i, k + 2);
        if TempCode[j].ID = 61 then begin
          NeedDefault := True;
          k := TempCode[j + 1].Value;
          Inc(j, k + 2);
        end;
      end;
    until TempCode[j].ID <> 44;
  end;
  if (i <> BOfs) and (TempCode[i - 1].ID <> 41) then begin
    SetError(erInvalidParams, TempCode[i].Line, FName);
    Exit;
  end;
  Inc(j);
  Tmp := FuncExit; FuncExit := False;
  t := Pre; Pre := LPre;
  if Execute(j, FName, True) and (rvt <> vtVoid) then
    Result := GetValue(FName + '.RESULT', -1, 0);
  Pre := t;
  FuncExit := Tmp;
  k := 0;
  while k <= LVars.Count - 1 do
    if Pos(FName, LVars[k].Name) <> 0 then LVars.Vars.Delete(k)
    else Inc(k);
  if rvt <> vtVoid then begin
    i := nLFuncs - 1;
    while Pos(FName + '.', LFunctions[i].Name) <> 0 do Dec(i);
    nLFuncs := i + 1;
    SetLength(LFunctions, nlFuncs);
  end;
end;

function TCompiler.Evaluate(const Pre: string; BOfs, EOfs, Level: Cardinal): Variant;
var
  i, j: Cardinal;
  sk: Integer;
  R1, R2: Variant;
  Flag, b, Adr, Ref: Boolean;
  VName, s: string;
  V: TVariable;
  FindInfo: TFindInfo;
begin
  Result := 0;
  if HasErr or (BOfs > EOfs) then Exit;
  i := EOfs;
  sk := 0;
  while i >= BOfs do begin
    if TempCode[i].ID in [41, 93] then Inc(sk);   // ), ]
    if TempCode[i].ID in [40, 91] then Dec(sk);   // (, [
    case Level of
      // <, >, ==, !=, >=, <=
      1: if sk = 0 then begin
          Flag := True;
          if TempCode[i].ID = 60 then
            Result := Evaluate(Pre, BOfs, i - 1, Level) < Evaluate(Pre, i + 1, EOfs, Level + 1)
          else if TempCode[i].ID = 62 then
            Result := Evaluate(Pre, BOfs, i - 1, Level) > Evaluate(Pre, i + 1, EOfs, Level + 1)
          else if TempCode[i].ID = EQ then begin
            R1 := Evaluate(Pre, BOfs, i - 1, Level);
            R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
            if CompareTypes(R1, R2) then Result := R1 = R2;
          end
          else if TempCode[i].ID = NE then
            Result := Evaluate(Pre, BOfs, i - 1, Level) <> Evaluate(Pre, i + 1, EOfs, Level + 1)
          else if TempCode[i].ID = GE then
            Result := Evaluate(Pre, BOfs, i - 1, Level) >= Evaluate(Pre, i + 1, EOfs, Level + 1)
          else if TempCode[i].ID = LE then
            Result := Evaluate(Pre, BOfs, i - 1, Level) <= Evaluate(Pre, i + 1, EOfs, Level + 1)
          else Flag := False;
          if Flag then Exit;
        end;
      // &&, ^, ||
      2: if sk = 0 then
          if (TempCode[i].ID = 94) or (TempCode[i].ID = _AND) or (TempCode[i].ID = _OR) then begin
            R1 := Evaluate(Pre, BOfs, i - 1, Level);
            if TempCode[i].ID = _AND then begin
              Result := R1;
              if Result then begin
                R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
                if CompareTypes(R1, R2) then Result := Boolean(R2)
                else SetError(erInvalidType, TempCode[i].Line, '');
              end;
            end
            else if TempCode[i].ID = _OR then begin
              Result := R1;
              if not Result then begin
                R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
                if CompareTypes(R1, R2) then Result := R2
                else SetError(erInvalidType, TempCode[i].Line, '');
              end;
            end
            else begin
              R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
              if CompareTypes(R1, R2) then Result := R1 xor R2
              else SetError(erInvalidType, TempCode[i].Line, '');
            end;
            Exit;
          end;
      // +, -
      3: if sk = 0 then
          if TempCode[i].ID in [43, 45] then begin
            R1 := Evaluate(Pre, BOfs, i - 1, Level);
            R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
            if CompareTypes(R1, R2) then begin
              if TempCode[i].ID = 43 then Result := R1 + R2
              else Result := R1 - R2;
            end
            else SetError(erInvalidType, TempCode[i].Line, '');
            Exit;
          end;
      // %, * /, \
      4: if (sk = 0) and (i > BOfs) then
          if TempCode[i].ID in [37, 42, 47, 92] then begin
            if (i > BOfs) and (TempCode[i - 1].ID = 42) then Dec(i);
            R1 := Evaluate(Pre, BOfs, i - 1, Level);
            R2 := Evaluate(Pre, i + 1, EOfs, Level + 1);
            if CompareTypes(R1, R2) then begin
              if TempCode[i].ID = 37 then
                if R2 <> 0 then Result := R1 mod R2 else SetError(erDivisionByZero, TempCode[i].Line, '')
              else if TempCode[i].ID = 42 then Result := R1 * R2
              else if TempCode[i].ID = 47 then
                if R2 <> 0 then Result := R1 / R2 else SetError(erDivisionByZero, TempCode[i].Line, '')
              else
                if R2 <> 0 then Result := R1 div R2 else SetError(erDivisionByZero, TempCode[i].Line, '');
            end
            else SetError(erInvalidType, TempCode[i].Line, '');
            Exit;
          end;
      // (), !, переменная, функция, константа
      5: if sk = 0 then begin
        Flag := True;
        i := BOfs;
        case TempCode[i].ID of
          // !
          33: Result := not Evaluate(Pre, BOfs + 1, EOfs, 1);
          // (
          40: Result := Evaluate(Pre, BOfs + 2, EOfs - 1, 1);
          // константа
          CINT..CSTRING: Result := TempCode[i].Value;
          // *, имя
          42, VARNAME: begin
              Adr := TempCode[i].ID = 42;
              Ref := False;
              if Adr then begin
                Inc(i);
                Ref := TempCode[i].ID = 40;
                if Ref then Inc(i);
              end;
              Inc(i);
              if TempCode[i].ID = 40 then
                Result := GetFuncValue(Pre, BOfs, EOfs)
              else begin
                Dec(i);
                VName := TempCode[i].Value;
                V := nil;
                if FindByName(Pre, VName, FindInfo) then begin
                  if FindInfo.VType = 0 then
                  V := TVariable(FindInfo.Variable);
                end
                else begin
                  SetError(erVarNotFound, TempCode[i].Line, VName);
                  Exit;
                end;

                b := False;
                if TempCode[i + 1].ID = 91 then begin
                  if TempCode[i + 2].ID = 93 then b := True
                  else begin
                    Inc(i, 2);
                    j := TempCode[i].Value;
                    R1 := Evaluate(Pre, i + 1, i + j, 1);
                    case VarType(R1) and VarTypeMask of
                      varSmallint, varInteger, varByte: ; // Nothing
                      else begin
                        SetError(erInvalidType, TempCode[i].Line, '');
                        Exit;
                      end;
                    end;
                    Inc(i, j + 1);
                  end;
                end
                else R1 := -1;

                if FindInfo.VType = 0 then
                  if b then
                    if V.Dim >= 0 then Result := Integer(V)
                    else SetError(erInvalidType, TempCode[i].Line, '')
                  else if Adr and (not Ref) and (R1 >= 0) then
                    if V.Values = nil then SetError(erNilPointer, TempCode[i].Line, V.Name)
                    else if V.Dim > 0 then SetError(erInvalidType, TempCode[i].Line, '')
                    else begin
                      s := TVariable(V.Values).Name;
                      Result := GetValue(s, R1, TempCode[i].Line, True);
                    end
                  else Result := GetValue(V.Name, R1, TempCode[i].Line, True, Adr)
                else Result := GetFuncValue(Pre, BOfs, EOfs);
              end;
            end;
          else Flag := False;
        end;
        if Flag then Exit;
      end;
    end;
    Dec(i);
  end;
  if Level <> 5 then Result := Evaluate(Pre, BOfs, EOfs, Level + 1);
end;

function TCompiler.Execute(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
begin
  Result := False;
//  if (CurTime > 0) and (CurTime < Now) then SetError(erTimeElapsed, 0, '');
  if HasErr then Exit;
  if CallMsg then Application.ProcessMessages;

  Result := True;
  case TempCode[TCFwd].ID of
    // ;
    59: Inc(TCFwd);
    // {
    123:
      begin
        Inc(TCFwd);
        while (TempCode[TCFwd].ID <> 125) and not HasErr do begin
          Result := Execute(TCFwd, Pre, Run);
          if FuncExit then Exit;
        end;
        Inc(TCFwd);
      end;
    // типы
    321..329: Result := ExecDecl(TCFwd, Pre, Run);
    // if
    301: Result := ExecIf(TCFwd, Pre, Run);
    // while
    302: Result := ExecWhile(TCFwd, Pre, Run);
    // do..while
    303: Result := ExecDo(TCFwd, Pre, Run);
    // repeat..until
    304: Result := ExecRepeat(TCFwd, Pre, Run);
    // for
    307: Result := ExecFor(TCFwd, Pre, Run);
    // exit
    308: begin FuncExit := True; Inc(TCFwd); end;
    // switch
    309: Result := ExecSwitch(TCFwd, Pre, Run);
    // new
    311: Result := ExecNew(TCFwd, Pre, Run);
    // free
    312: Result := ExecFree(TCFwd, Pre, Run);
    // переменные, указатели, массивы, функции
    42, VARNAME: Result := ExecVar(TCFwd, Pre, Run);
  end;
end;

function TCompiler.AddFunc(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  sk, n: Integer;
  s: string;
begin
  s := Pre + TempCode[TCFwd - 1].Value;
  n := -1;
  if Run then begin
    Result := not (XVars.SearchVar(s, sk) or GVars.SearchVar(s, sk));
    if not Result then SetError(erAlreadyDefined, TempCode[TCFwd].Line, s)
    else begin
      for sk := 0 to nLFuncs - 1 do
{$IFDEF PULSE}
        if StrCompareExtW(PChar(LFunctions[sk].Name), PChar(s), 0, False) = 0 then begin
{$ELSE}
        if CompareStrFlags2(PChar(LFunctions[sk].Name), PChar(s), False) = 0 then begin
{$ENDIF}
          n := sk;
          Break;
        end;
    end;
  end
  else Result := True;

  if Result and Run then begin
    if n < 0 then begin
      SetLength(LFunctions, nLFuncs + 1);
      n := nLFuncs;
      Inc(nLFuncs);
    end;
    with LFunctions[n] do begin
      Pos := TCFwd - 2;
      Name := s;
    end;
  end;
  while TempCode[TCFwd].ID <> 123 do
    if TempCode[TCFwd].ID = 1000 then Inc(TCFwd, Cardinal(TempCode[TCFwd].Value) + 1)
    else Inc(TCFwd);
  sk := 0;
  repeat
    if TempCode[TCFwd].ID = 123 then Inc(sk)
    else if TempCode[TCFwd].ID = 125 then Dec(sk);
    if TempCode[TCFwd].ID = 1000 then Inc(TCFwd, Cardinal(TempCode[TCFwd].Value) + 1)
    else Inc(TCFwd);
  until sk = 0;
end;

function TCompiler.ExecDecl(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  vt: VariableType;
  i: Integer;
  VName, s: string;
  V: Variant;
  IsArray: Boolean;
  Vr: TVariable;
begin
  vt := GetType(TempCode[TCFwd].ID);
  Result := True;
  if Pre <> '' then VName := Pre + '.' else VName := '';
  repeat
    IsArray := False;
    Inc(TCFwd);
    if TempCode[TCFwd + 1].ID <> 40 then            // (
      if TempCode[TCFwd + 1].ID <> 91 then begin    // [
        if Run then Result := Result and AddVariable(VName + TempCode[TCFwd].Value, vt);
      end
      else begin
        s := VName + TempCode[TCFwd].Value;
        Inc(TCFwd, 2);
        if TempCode[TCFwd].ID = 93 then V := 0
        else begin
          i := TempCode[TCFwd].Value;
          if Run then V := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1) else V := 0;
          Result := Result and not HasErr;
          Inc(TCFwd, 3);
        end;
        if Run then case VarType(V) and VarTypeMask of
          varSmallint, varInteger, varByte:
            begin
              Result := not (GVars.SearchVar(s, I) or LVars.SearchVar(s, I) or XVars.SearchVar(s, I));
              if Result then LVars.AddVariable(s, vt, 0, False, Integer(V))
              else begin
                Vr := GetVar(s);
                if Vr.VType <> vt then SetError(erAlreadyDefined, TempCode[TCFwd].Line, s)
                else Result := True;
              end;
            end;
          else begin
            SetError(erInvalidType, TempCode[TCFwd].Line, '');
            Result := False;
          end;
        end;
        IsArray := True;
      end;
    Inc(TCFwd);
    if TempCode[TCFwd].ID = 61 then begin   // =
      if Run and IsArray then begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Run := False;
      end;
      if Run and (vt = vtPointer) then begin
        Inc(TCFwd);
        SetPointer('', VName + TempCode[TCFwd - 2].Value, TCFwd, Run);
        Result := Result and not HasErr;
      end
      else begin
        Inc(TCFwd);
        i := TempCode[TCFwd].Value;
        if Run then
          SetValue(VName + TempCode[TCFwd - 2].Value, Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1), -1, TempCode[TCFwd].Line);
        Result := Result and not HasErr;
        Inc(TCFwd, i + 1);
      end;
    end
    else if TempCode[TCFwd].ID = 40 then AddFunc(TCFwd, VName, Run);
  until (TempCode[TCFwd].ID <> 44) or not Result;
end;

function TCompiler.ExecIf(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag: Boolean;
  i: Integer;
begin
  Inc(TCFwd, 2);
  i := TempCode[TCFwd].Value;
  if Run then Flag := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1) else Flag := True;
  Result := not HasErr;
  Inc(TCFwd, i + 2);
  if Flag then Result := Result and Execute(TCFwd, Pre, Run)
  else Result := Result and Execute(TCFwd, Pre, False);
  if TempCode[TCFwd].ID = 306 then begin      // ELSE
    Inc(TCFwd);
    if Flag then Result := Result and Execute(TCFwd, Pre, False)
    else Result := Result and Execute(TCFwd, Pre, Run);
  end;
end;

function TCompiler.ExecWhile(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag: Boolean;
  i, j: Integer;
begin
  Inc(TCFwd, 2);
  i := TempCode[TCFwd].Value;
  j := Integer(TCFwd) + i;
  i := TCFwd + 1;
  repeat
    TCFwd := j + 2;
    if Run then Flag := Evaluate(Pre, i, j, 1) else Flag := False;
    Result := not HasErr;
    if Flag then Result := Result and Execute(TCFwd, Pre, Run)
    else Result := Result and Execute(TCFwd, Pre, False);
  until (not Flag) or (not Result);
end;

function TCompiler.ExecDo(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag: Boolean;
  i, j: Integer;
begin
  Inc(TCFwd);
  i := TCFwd;
  repeat
    TCFwd := i;
    Result := Execute(TCFwd, Pre, Run);
    Inc(TCFwd, 2);
    j := TempCode[TCFwd].Value;
    if Run then Flag := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(j), 1) else Flag := False;
    Result := Result and not HasErr;
    Inc(TCFwd, j + 2);
  until (not Flag) or (not Result);
end;

function TCompiler.ExecRepeat(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag: Boolean;
  i, j: Integer;
begin
  Inc(TCFwd);
  i := TCFwd;
  repeat
    TCFwd := i;
    Result := Execute(TCFwd, Pre, Run);
    Inc(TCFwd, 2);
    j := TempCode[TCFwd].Value;
    if Run then Flag := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(j), 1) else Flag := True;
    Result := Result and not HasErr;
    Inc(TCFwd, j + 2);
  until Flag or (not Result);
end;

function TCompiler.ExecFor(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag, b: Boolean;
  i, j, k: Cardinal;
begin
  Inc(TCFwd, 2);
  Result := Execute(TCFwd, Pre, Run);
  Inc(TCFwd);
  i := TCFwd;
  Inc(TCFwd, Integer(TempCode[i].Value) + 2);
  j := TCFwd;
  Flag := Execute(TCFwd, Pre, False);
  Result := Result and Flag;
  k := TCFwd + 1;
  repeat
    if Run and Result then Flag := Evaluate(Pre, i + 1, j - 1, 1) else Flag := False;
    Result := Result and not HasErr;
    if Flag then begin
      TCFwd := k;
      Result := Result and Execute(TCFwd, Pre, Run);
      TCFwd := j;
      Result := Result and Execute(TCFwd, Pre, Run);
    end
    else begin
      TCFwd := k;
      b := Execute(TCFwd, Pre, False);
      Result := Result and b;
    end;
  until (not Flag) or (not Result);
end;

function TCompiler.ExecSwitch(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  Flag: Boolean;
  i: Cardinal;
  V1, V2: Variant;
begin
  Result := True;
  Inc(TCFwd, 2);
  i := TempCode[TCFwd].Value;
  if Run then V1 := Evaluate(Pre, TCFwd + 1, TCFwd + i, 1) else V1 := 0;
  Inc(TCFwd, i + 3);
  while TempCode[TCFwd].ID <> 125 do begin
    if TempCode[TCFwd].ID = 310 then begin       // DEFAULT
      Inc(TCFwd, 2);
      Result := Result and Execute(TCFwd, Pre, Run);
    end
    else begin                                // Очередное выражение
      Flag := False;
      repeat
        i := TempCode[TCFwd].Value;
        if not Flag then begin
          if Run then V2 := Evaluate(Pre, TCFwd + 1, TCFwd + i, 1) else V2 := 0;
          if CompareTypes(V1, V2) and (V1 = V2) then Flag := True;
        end;
        Inc(TCFwd, i + 1);
        if TempCode[TCFwd].ID = 44 then Inc(TCFwd); // ,
      until TempCode[TCFwd].ID = 58;    // :
      Inc(TCFwd);
      if Flag then begin
        Result := Result and Execute(TCFwd, Pre, Run);
        Run := False;
      end
      else Result := Result and Execute(TCFwd, Pre, False);
    end;
    if TempCode[TCFwd].ID = 59 then Inc(TCFwd);
  end;
  Inc(TCFwd);
end;

function TCompiler.ExecNew(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  V, P: TVariable;
  i, Index: Integer;
  vt: VariableType;
  Val: Variant;
  VName: string;
  FindInfo: TFindInfo;
begin
  Result := True;
  V := nil; Index := -1;
  Inc(TCFwd, 2);
  if Run then begin
    VName := TempCode[TCFwd].Value;
    if FindByName(Pre, VName, FindInfo) then begin
      if (FindInfo.VType = 0) and (FindInfo.Variable.VType = vtPointer) then V := TVariable(FindInfo.Variable)
      else begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Run := False;
      end;
    end
    else begin
      SetError(erVarNotFound, TempCode[TCFwd].Line, VName);
      Run := False;
    end;
  end;
  if TempCode[TCFwd + 1].ID = 91 then begin
    if Run and (TempCode[TCFwd + 2].ID = 93) then begin
      SetError(erInvalidType, TempCode[TCFwd].Line, '');
      Run := False;
      Inc(TCFwd, 3);
    end
    else begin
      if Run and (V <> nil) then
        if V.Dim < 0 then begin
          SetError(erInvalidType, TempCode[TCFwd].Line, '');
          Run := False;
        end;
      Inc(TCFwd, 2);
      i := TempCode[TCFwd].Value;
      if Run then
        Index := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1);
      Result := not HasErr;
      Inc(TCFwd, i + 3);
    end;
  end
  else begin
    if Run and (V <> nil) then
      if V.Dim >= 0 then begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Result := False;
        Run := False;
      end;
    Index := -1;
    Inc(TCFwd, 2);
  end;
  Inc(TCFwd);
  if Run then begin
    vt := GetType(TempCode[TCFwd - 1].ID);
    P := TVariable.Create('');
    P.VType := vt;
    if V.Dim < 0 then V.Values := P
    else TAPointer(V.Values)[Index] := P;
  end;
  if TempCode[TCFwd].ID = 41 then Inc(TCFwd)
  else begin
    Inc(TCFwd);
    i := TempCode[TCFwd].Value;
    if Run then begin
      Val := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1);
      Result := Result and not HasErr;
      SetValue(V.Name, Val, Index, TempCode[TCFwd].Line);
    end;
    Inc(TCFwd, i + 2);
  end;
end;

function TCompiler.ExecFree(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  V: TVariable;
  i, Index: Integer;
  s: string;
  FindInfo: TFindInfo;
begin
  Result := True;
  Inc(TCFwd, 2);
  Index := -1;
  V := nil;
  if Run then begin
    s := TempCode[TCFwd].Value;
    if FindByName(Pre, s, FindInfo) then begin
      if (FindInfo.VType = 0) and (FindInfo.Variable.VType = vtPointer) then V := TVariable(FindInfo.Variable)
      else begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Run := False;
      end;
    end
    else begin
      SetError(erVarNotFound, TempCode[TCFwd].Line, s);
      Run := False;
    end;
  end;
  if TempCode[TCFwd + 1].ID = 91 then begin
    if Run and (TempCode[TCFwd + 2].ID = 93) then begin
      SetError(erInvalidType, TempCode[TCFwd].Line, '');
      Run := False;
      Inc(TCFwd, 3);
    end
    else begin
      if Run and (V <> nil) then
        if V.Dim < 0 then begin
          SetError(erInvalidType, TempCode[TCFwd].Line, '');
          Run := False;
        end;
      Inc(TCFwd, 2);
      i := TempCode[TCFwd].Value;
      if Run then
        Index := Evaluate(Pre, TCFwd + 1, TCFwd + Cardinal(i), 1);
      Result := Result and not HasErr;
      Inc(TCFwd, i + 3);
    end;
  end
  else begin
    if Run and (V <> nil) then
      if V.Dim >= 0 then begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Run := False;
      end;
    Index := -1;
    Inc(TCFwd, 2);
  end;
  if Run then
    if (V <> nil) and (V.Dim < 0) then begin
      if (V.Values <> nil) and (TVariable(V.Values).Name = '') then begin
        TVariable(V.Values).Free;
        V.Values := nil;
      end;
    end
    else if (Pointer(TAPointer(V.Values)[Index]) <> nil)
      and (TVariable(Pointer(TAPointer(V.Values)[Index])).Name = '') then begin
      TVariable(TAPointer(V.Values)[Index]).Free;
      TAPointer(V.Values)[Index] := nil;
    end;
end;

function TCompiler.ExecVar(var TCFwd: Cardinal; const Pre: string; Run: Boolean): Boolean;
var
  i, j, sk: Cardinal;
  s: string;
  Index: Variant;
  Adr, Ref: Boolean;
  FindInfo: TFindInfo;
  V: TVariable;
begin
  Ref := False;
  Adr := TempCode[TCFwd].ID = 42;
  if Adr then begin
    Inc(TCFwd);
    Ref := TempCode[TCFwd].ID = 40;
    if Ref then Inc(TCFwd);
  end;
  Inc(TCFwd);
  V := nil;
  Result := True;
  if Run then begin
    s := TempCode[TCFwd - 1].Value;
    if FindByName(Pre, s, FindInfo) then begin
      if FindInfo.VType = 0 then V := TVariable(FindInfo.Variable);
    end
    else begin
      SetError(erVarNotFound, TempCode[TCFwd].Line, s);
      Run := False;
      Result := False;
    end;
  end;

  i := TCFwd;
  if TempCode[i].ID = 91 then begin
    if Run and (TempCode[i + 1].ID = 93) then begin
      SetError(erInvalidType, TempCode[i].Line, '');
      Result := False;
      Run := False;
    end;
    Inc(i);
    j := TempCode[i].Value;
    if Run then begin
      Index := Evaluate(Pre, i + 1, i + j, 1);
      Result := Result and not HasErr;
      case VarType(Index) and VarTypeMask of
        varSmallint, varInteger, varByte: ;
        else begin
          SetError(erInvalidType, TempCode[i].Line, '');
          Result := False;
          Run := False;
        end;
      end;
    end;
    TCFwd := i + j + 2;
  end
  else Index := -1;
  if Ref then Inc(TCFwd);

  i := TCFwd;
  if TempCode[i].ID = 61 then begin
    if Run and (FindInfo.VType <> 0) then begin
      SetError(erInvalidType, TempCode[i].Line, '');
      Result := False;
      Run := False;
    end;
    Inc(i);
    j := TempCode[i].Value;
    Inc(TCFwd);
    if Run then
      if (V.VType = vtPointer) and not Adr then begin
        SetPointer(Pre, V.Name, TCFwd, True, Index);
        Result := Result and not HasErr;
      end
      else
        if Adr and (not Ref) and (Index >= 0) then begin
          if V <> nil then begin
            if V.Values = nil then begin
              SetError(erNilPointer, TempCode[i - 1].Line, V.Name);
              Result := False;
            end;
            if V.Dim > 0 then begin
              SetError(erInvalidType, TempCode[i - 1].Line, '');
              Result := False;
            end
            else
              Result := Result and SetValue(TVariable(V.Values).Name, Evaluate(Pre, i + 1, i + j, 1), Index, TempCode[i - 1].Line);
          end;
        end
        else Result := Result and SetValue(V.Name, Evaluate(Pre, i + 1, i + j, 1), Index, TempCode[i - 1].Line, Adr);
    TCFwd := i + j + 1;
    Exit;
  end
  else begin
    if Run and (FindInfo.VType = 0) then begin
      SetError(erInvalidType, TempCode[i].Line, '');
      Result := False;
      Run := False;
    end;
    TCFwd := i;
    if TempCode[i].ID = 40 then begin       // (
      sk := 0;
      repeat
        if TempCode[TCFwd].ID = 40 then Inc(sk)
        else if TempCode[TCFwd].ID = 41 then Dec(sk);
        if TempCode[TCFwd].ID = 1000 then Inc(TCFwd, Integer(TempCode[TCFwd].Value) + 1)
        else Inc(TCFwd);
      until sk = 0;
    end;
    if Run then begin
      GetFuncValue(Pre, i - 1, TCFwd - 1);
      Result := Result and not HasErr;
    end;
  end;
end;

procedure TCompiler.AddTemp(const Token: TToken);
begin
  if (TCFwd + 1) >= TCL then begin
    Inc(TCL, 100);
    SetLength(TempCode, TCL);
  end;
  TempCode[TCFwd] := Token;
  Inc(TCFwd);
end;

function TCompiler.SearchLocalFunc(const Name: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to nLFuncs - 1 do
{$IFDEF PULSE}
    if StrCompareExtW(PChar(LFunctions[i].Name), PChar(Name), 0, False) = 0 then begin
{$ELSE}
    if CompareStrFlags2(PChar(LFunctions[i].Name), PChar(Name), False) = 0 then begin
{$ENDIF}
      Result := i;
      Break;
    end;
end;

function TCompiler.FindByName(Pre, Name: string; var FindInfo: TFindInfo): Boolean;
var
  i, n: Integer;
begin
  Result := True;
  if Pre <> '' then Pre := Pre + '.';
  repeat
    if LVars.SearchVar(Pre + Name, n) then begin
      FindInfo.VType := 0;
      FindInfo.Variable := LVars[n];
      Exit;
    end
    else begin
      n := SearchLocalFunc(Pre + Name);
      if n >=0 then begin
        FindInfo.VType := 1;
        FindInfo.Index := n;
        Exit;
      end;
    end;
    i := Length(Pre) - 1;
    while (i > 0) and (Pre[i] <> '.') do Dec(i);
    if i = 0 then Pre := '' else Delete(Pre, i + 1, Length(Pre) - i);
  until i < 0;
  if GVars.SearchVar(Name, n) then begin
    if GVars[n] is TVariable then FindInfo.VType := 0
    else FindInfo.VType := 2;
    FindInfo.Variable := GVars[n];
    Exit;
  end
  else if XVars.SearchVar(Name, n) then begin
    if XVars[n] is TVariable then FindInfo.VType := 0
    else FindInfo.VType := 2;
    FindInfo.Variable := XVars[n];
    Exit;
  end;
  Result := False;
end;

procedure TCompiler.SetError(EType, Line: Integer; EStr: string);
var
  S: string;
  I: Integer;
  c: Cardinal;
begin
  if EType in [erSyntax, erDivisionByZero, erInvalidVar, erTimeElapsed] then HasErr := True
    else HasErr := ErrExit;
  if WaitForSingleObject(ErrMutex, 0) = WAIT_OBJECT_0 then begin
    S := Errors[EType];
    if Line <> 0 then
{$IFDEF LANGENG}
      S := 'line '
{$ELSE}
      S := 'строка '
{$ENDIF}
      + IntToStr(Line) + ': ' + S;
    if EType in [erSyntax, erInvalidType, erInvalidVar, erDivisionByZero] then begin
      c := 1; I := 1;
      while (c < SL) and (I < Line) do begin
        if Script[c] = #13 then Inc(I);
        Inc(c);
      end;
      if Script[c] in [#10, #13] then Inc(c);
      while (c < SL) and not (Script[c] in [#10, #13]) do begin
        EStr := EStr + Script[c];
        Inc(c);
      end;
      EStr := DelRSpace(EStr);
      EStr := DelSpace1(EStr);
      if Length(EStr) > 2 then begin
        if EStr[1] = '{' then Delete(EStr,1,1);
        if EStr[Length(EStr)] = '}' then SetLength(EStr, Length(EStr) - 1);
      end;
      EStr := DelRSpace(EStr);
      EStr := DelSpace1(EStr);
    end;
    I := Pos(#1, S);
    if I <> 0 then begin
      Delete(S, I, 1);
      Insert(EStr, S, I);
    end;
{$IFDEF PULSE}
    Msg.ErrorToLog(Pref + S);
{$ENDIF}
    if Assigned(GlobalCompilerErrFunc) then GlobalCompilerErrFunc(S);
    if Assigned(FErrFunc) then FErrFunc(S);
    LastError := S;
    ReleaseMutex(ErrMutex);
  end;
end;

function TCompiler.SearchSymbol(const Name: string): Boolean;
var
  I: Integer;
begin
  Result := GVars.SearchVar(Name, I) or LVars.SearchVar(Name, I) or XVars.SearchVar(Name, I);
end;

function TCompiler.GetVar(const Name: string): TVariable;
var
  I: Integer;
begin
  Result := nil;
  if GVars.SearchVar(Name, I) then
    if GVars[I] is TVariable then begin
      Result := TVariable(GVars[I]);
      Exit;
    end;
  if LVars.SearchVar(Name, I) then
    if LVars[I] is TVariable then begin
      Result := TVariable(LVars[I]);
      Exit;
    end;
  if XVars.SearchVar(Name, I) then Result := TVariable(XVars[I]);
end;

procedure TCompiler.SetPointer(const Pre, Name: string; var TCFwd: Cardinal;
  Run: Boolean; const Index: Integer = -1);
var
  i: Cardinal;
  n, k, j: Integer;
  s, vn: string;
  Flag: Boolean;
begin
  if Run and not LVars.SearchVar(Name, n) then begin
    SetError(erVarNotFound, TempCode[TCFwd].Line, Name);
    Run := False;
  end;
  i := TempCode[TCFwd].Value;
  Inc(TCFwd);
  Flag := TempCode[TCFwd].ID = 64;   // @
  if Flag then begin
    Inc(TCFwd); Dec(i);
  end;
  vn := TempCode[TCFwd].Value;
  if Pre <> '' then s := Pre else s := '';
  s := s + vn;
  Inc(TCFwd); Dec(i);
  if i <> 0 then begin
    if Run then SetError(erInvalidType, TempCode[TCFwd].Line, '');
    while not (TempCode[TCFwd].ID in [59, 125]) do
      if TempCode[TCFwd].ID = 1000 then Inc(TCFwd, Integer(TempCode[TCFwd].Value) + 1)
      else Inc(TCFwd);
    Exit;
  end;
  if Run then begin
    while s <> '' do begin
      if LVars.SearchVar(s, k) then Break;
      k := -1;
      j := Length(s);
      repeat Dec(j); until (s[j] = '.') or (j = 0);
      if j = 0 then s := ''
      else Delete(s, j, Length(s) - Integer(j) + 1);
    end;
    if k = -1 then begin
      if GVars.SearchVar(vn, k) or XVars.SearchVar(Name, k) then
        SetError(erInvalidType, TempCode[TCFwd].Line, '')
      else
        SetError(erVarNotFound, TempCode[TCFwd].Line, vn);
      Exit;
    end;
    if not Flag then
      if LVars[k].VType <> vtPointer then begin
        SetError(erInvalidType, TempCode[TCFwd].Line, '');
        Exit;
      end
      else if TVariable(LVars[k]).Values = nil then begin
        SetError(erNilPointer, TempCode[TCFwd].Line, s);
        Exit;
      end;
    if (LVars[n].Dim < 0) and (Index >= 0) then
      SetError(erInvalidType, TempCode[TCFwd].Line, '')
    else if (LVars[n].Dim >= 0) and ((LVars[n].Dim <= Index) or (Index < 0)) then
      SetError(erOutOfRange, TempCode[TCFwd].Line, Name);
    if Index < 0 then
      if LVars[k].VType <> vtPointer then TVariable(LVars[n]).Values := TVariable(LVars[k])
      else TVariable(LVars[n]).Values := TVariable(LVars[k]).Values
    else
      if LVars[k].VType <> vtPointer then TAPointer(TVariable(LVars[n]).Values)[Index] := TVariable(LVars[k])
      else TAPointer(TVariable(LVars[n]).Values)[Index] := TVariable(LVars[k]).Values;
  end;
end;

function TCompiler.SetValue(VName: string; Value: Variant; const Index: Integer = -1; const Line: Integer = 0; const Adr: Boolean = False): Boolean;
var
  I: Integer;
begin
  Result := False;
  if HasErr then Exit;
  if GVars.SearchVar(VName, I) then begin
    Result := GVars[I].SetValue(Value);
    if not Result then SetError(erConstAssigned, Line, VName);
  end
  else if LVars.SearchVar(VName, I) then begin
    if (LVars[I].VType <> vtPointer) and Adr then
      SetError(erInvalidType, Line, '')
    else if (LVars[I].Dim < 0) and (Index >= 0) then
      SetError(erInvalidType, Line, '')
    else if (LVars[I].Dim >= 0) and ((LVars[I].Dim <= Index) or (Index < 0)) then
      SetError(erOutOfRange, Line, VName)
    else if (LVars[I].VType = vtPointer) and
      (((LVars[I].Dim < 0) and (TVariable(LVars[I]).Values = nil))
        or ((LVars[I].Dim >= 0) and (TAPointer(TVariable(LVars[I]).Values)[Index] = nil))) then begin
        if Index >= 0 then VName := VName + '[' + IntToStr(Index) + ']';
        SetError(erNilPointer, Line, VName);
      end
    else begin
      Result := LVars[I].SetValue(Value, Index);
      if not Result then SetError(erConstAssigned, Line, VName);
    end;
  end
  else if XVars.SearchVar(VName, I) then begin
    if (XVars[I].VType <> vtPointer) and Adr then
      SetError(erInvalidType, Line, '')
    else if (XVars[I].Dim >= 0) and ((XVars[I].Dim <= Index) or (Index < 0)) then
      SetError(erOutOfRange, Line, VName)
    else begin
      Result := XVars[I].SetValue(Value, Index);
      if not Result then SetError(erConstAssigned, Line, VName);
    end;
  end
  else
    SetError(erVarNotFound, Line, VName);
end;

function TCompiler.GetValue(VName: string; const Index: Integer = -1; const Line: Integer = 0; const NA: Boolean = False; const Adr: Boolean = False): Variant;
var
  I: Integer;
  V: TVariable;
begin
  Result := 0;
  if HasErr then Exit;
  V := nil;
  if LVars.SearchVar(VName, I) then begin
    if LVars[I] is TVariable then begin
      if (LVars[I].Dim < 0) and (Index >= 0) then begin
        SetError(erInvalidType, Line, '');
        Exit;
      end
      else if (LVars[I].Dim >= 0) and (LVars[I].Dim <= Index) then begin
        SetError(erOutOfRange, Line, VName);
        Exit;
      end
      else if (LVars[I].Dim >=0) and (Index < 0) and NA then begin
        SetError(erVarNotFound, Line, VName);
        Exit;
      end;
      if LVars[I].VType = vtPointer then begin
        if not Adr then begin
          SetError(erInvalidType, Line, '');
          Exit;
        end;
        if ((LVars[I].Dim < 0) and (TVariable(LVars[I]).Values = nil))
          or ((LVars[I].Dim >= 0) and (TAPointer(TVariable(LVars[I]).Values)[Index] = nil)) then begin
          if Index >= 0 then VName := VName + '[' + IntToStr(Index) + ']';
          SetError(erNilPointer, Line, VName);
          Exit;
        end;
      end;
      V := TVariable(LVars[I]);
    end;
  end
  else if GVars.SearchVar(VName, I) then begin
    if GVars[I] is TVariable then V := TVariable(GVars[I]);
  end
  else if XVars.SearchVar(VName, I) then
    if XVars[I] is TVariable then begin
      if (XVars[I].Dim >= 0) and ((XVars[I].Dim <= Index) or (Index < 0)) then begin
        SetError(erOutOfRange, Line, VName);
        Exit;
      end
      else V := TVariable(XVars[I]);
    end;

  if V = nil then begin
    SetError(erVarNotFound, Line, VName);
    Result := 0;
  end
  else if (V.VType <> vtPointer) and Adr then SetError(erInvalidType, 0, '')
  else Result := V.GetValue(Index);
end;

function TCompiler.AddVariable(Name: string; VType: VariableType;
  Value: Integer = 0; IsConst: Boolean = False): Boolean;
var
  I: Integer;
  V: TVariable;
begin
  Result := not (GVars.SearchVar(Name, I) or LVars.SearchVar(Name, I) or XVars.SearchVar(Name, I));
  if Result then LVars.AddVariable(Name, VType, Value, False)
  else begin
    V := GetVar(Name);
    if V.VType <> VType then SetError(erAlreadyDefined, 0, Name)
    else Result := True;
  end;
end;

function TCompiler.RegistryString;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarString, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryStringS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarString, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryInteger;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarInteger, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryIntegerS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarInteger, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryFloat;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarFloat, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryFloatS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarFloat, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryBoolean;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarBool, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryBooleanS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarBool, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryNatural;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarNatural, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryNaturalS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarNatural, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryPercent;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarPercent, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryPercentS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarPercent, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryColor;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarColor, AObject, @V, @OnChange, AConst, True);
end;

function TCompiler.RegistryColorS;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegisterVariable(Name, vtVarColor, nil, @V, @OnChange, AConst, False);
end;

function TCompiler.RegistryArray(Name: string; VType: VariableType; Dim: Integer): Boolean;
begin
  Result := SearchSymbol(Name);
  if not Result then
    Result := XVars.RegistryArray(Name, VType, Dim);
end;

function TCompiler.RegistryFunction;
begin
  Result := SearchSymbol(FName);
  if not Result then
    Result := XVars.RegistryFunction(FName, Ptr, AObject, AResult, VarArray);
end;

function TCompiler.RegistryFunctionName(FName: string; Ptr: Pointer): Boolean;
begin
  Result := SearchSymbol(FName);
  if not Result then
    Result := XVars.RegistryFunction(FName, Ptr, nil, vtVoid, []);
end;

function TCompiler.RegistryFunctionNameS(FName: string; Ptr: Pointer): Boolean;
begin
  Result := SearchSymbol(FName);
  if not Result then
    Result := XVars.RegistryFunctionS(FName, Ptr, vtVoid, []);
end;

function TCompiler.RegistryFunctionS;
begin
  Result := SearchSymbol(FName);
  if not Result then
    Result := XVars.RegistryFunctionS(FName, Ptr, AResult, VarArray);
end;

procedure TCompiler.SetLengthA(AIndex, Dim: Integer);
var
  i: Integer;
  V: TVariable;
  Ps: ^string;
  AName: string;
begin
  V := TVariable(AIndex);
  AName := V.Name;
  if Dim < 0 then SetError(erOutOfRange, ErrLine, AName)
  else begin
    if V.Dim >= 0 then begin
      if Dim <> V.Dim then begin
        if (Dim < V.Dim) and (V.VType = vtString) then
          for i := Dim to V.Dim - 1 do begin
            Ps := TAPointer(V.Values)[i];
            if Ps <> nil then Dispose(Ps);
          end;
        case V.VType of
{$IFDEF PULSE}
          vtInteger, vtNatural, vtString: V.Values := ReallocMem(V.Values, Dim * SizeOf(Integer));
          vtPointer: V.Values := ReallocMem(V.Values, Dim * SizeOf(Pointer));
          vtColor: V.Values := ReallocMem(V.Values, Dim * SizeOf(TColor));
          vtBool: V.Values := ReallocMem(V.Values, Dim * SizeOf(Boolean));
          vtFloat, vtPercent: V.Values := ReallocMem(V.Values, Dim * SizeOf(Double));
{$ELSE}
          vtInteger, vtNatural, vtString: V.Values := ReallocMemory(V.Values, Dim * SizeOf(Integer));
          vtPointer: V.Values := ReallocMemory(V.Values, Dim * SizeOf(Pointer));
          vtColor: V.Values := ReallocMemory(V.Values, Dim * SizeOf(TColor));
          vtBool: V.Values := ReallocMemory(V.Values, Dim * SizeOf(Boolean));
          vtFloat, vtPercent: V.Values := ReallocMemory(V.Values, Dim * SizeOf(Double));
{$ENDIF}
        end;
        if Dim > V.Dim then
          for i := V.Dim to Dim - 1 do case V.VType of
            vtInteger, vtNatural: TAInteger(V.Values)[i] := 0;
            vtPointer: TAPointer(V.Values)[i] := nil;
            vtColor: TAColor(V.Values)[i] := clWhite;
            vtBool: TABool(V.Values)[i] := False;
            vtFloat, vtPercent: TAFloat(V.Values)[i] := 0;
            vtString:
              begin
                New(Ps);
                Ps^ := '';
                TAPointer(V.Values)[i] := Ps;
              end;
          end;
        V.Dim := Dim;
      end;
    end
    else SetError(erInvalidType, ErrLine, '');
  end;
end;

function TCompiler.ToStr(const Pre: string; BOfs: Cardinal): string;
var
  V: Variant;
  i: Cardinal;
//  FindInfo: TFindInfo;
begin
  Result := '';
  Inc(BOfs);
  if TempCode[Bofs].ID = 40 then begin
    Inc(BOfs);
    i := TempCode[BOfs].Value;
    if TempCode[BOfs + i + 1].ID <> 41 then SetError(erInvalidType, TempCode[BOfs].Line, '');
    V := Evaluate(Pre, BOfs + 1, BOfs + i, 1);
    if HasErr then Exit;
    Result := string(V);

  {    if Convert(V, VOut, V.VType, vtString) then Result := string(VOut);

    if TempCode[BOfs].ID <> VARNAME then SetError(erInvalidType, TempCode[BOfs].Line, '')
    else
      if TempCode[BOfs + 1].ID <> 41 then SetError(erInvalidType, TempCode[BOfs].Line, '')
      else if FindByName(Pre, TempCode[BOfs].Value, FindInfo) then
        if FindInfo.VType = 0 then begin
          V := TVariable(FindInfo.Variable);
          if Convert(V.Value, VOut, V.VType, vtString) then Result := string(VOut);
        end
        else SetError(erInvalidType, TempCode[BOfs].Line, '')
      else SetError(erVarNotFound, TempCode[BOfs].Line, TempCode[BOfs].Value)}
  end;
end;

procedure TCompiler.Prepare(const S: TStrings);
begin
  WaitForObjectFull;

  Script := S.Text;
  SL := Length(Script);
  Fwd := 1;
  HasErr := False;
  nLFuncs := 0;
  TCL := 0;
  TCFwd := 0;
  LineNo := 1;
  ErrLine := 1;
  DSep := DecimalSeparator;
  DecimalSeparator := '.';
end;

procedure TCompiler.Finalize;
begin
  Script := '';
  LVars.Clear;
  SetLength(LFunctions, 0);
  SetLength(TempCode, 0);
  SetLength(Cache, 0);
  DecimalSeparator := DSep;

  ReleaseObjectFull;
end;

function TCompiler.Compile(S: TStrings): Boolean;
begin
  Prepare(S);
  FillCache;
  Result := MatchBlock(20);
  Finalize;
end;

function TCompiler.Translate(S: TStrings; const AError: Boolean;
  const CallMessages: Boolean; const AMaxTime: Integer): Boolean;
begin
  Result := False;
  MaxTime := AMaxTime;
  ErrExit := AError;
  CallMsg := CallMessages;
  if MaxTime > 0 then CurTime := Now + MaxTime / 1000 / 24 / 3600 else CurTime := 0;

  Prepare(S);
{$IFDEF PCDEBUG}
  QueryPerformanceCounter(TM1);
{$ENDIF}

  if FillCache then
    if MatchBlock(20) then begin
      ErrLine := 0;
      TCFwd := 0;
      FuncExit := False;
      try
        Result := Execute(TCFwd, '', True);
      except
        SetError(erTimeElapsed, 0, '');
      end;
  {$IFDEF PCDEBUG}
    QueryPerformanceCounter(TM2);
  {$ENDIF}
    end
    else SetError(erSyntax, ErrLine, '');

  Finalize;
end;

function TCompiler.TranslateStr(S: string): Boolean;
var
  SList: TStringList;
begin
  SList := TStringList.Create;
  SList.Add(S);
  Result := Translate(SList, True, True, -1);
  SList.Free;
end;

procedure TCompiler.ChangeStatus(S: Boolean);
begin
  if IsExecuted and not S then begin
    HasErr := True;
    WaitForSingleObject(MExec, INFINITE);
    ReleaseMutex(MExec);
  end;
end;

function TCompiler.IsExecuted;
begin
  if WaitForSingleObject(MExec, 0) = WAIT_OBJECT_0 then begin
    ReleaseMutex(MExec);
    Result := False;
  end
  else Result := True;
end;

end.
