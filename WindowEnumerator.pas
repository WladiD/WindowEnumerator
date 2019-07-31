unit WindowEnumerator;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  System.Types,
  System.SysUtils,
  System.Generics.Collections;

const
  CLSID_VirtualDesktopManager: TGUID = '{AA509086-5CA9-4C25-8F95-589D3C07B48A}';
  IID_VirtualDesktopManager: TGUID = '{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}';

type
  IVirtualDesktopManager = interface(IUnknown)
    ['{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}']
    function IsWindowOnCurrentVirtualDesktop(Wnd: HWND; pIsTrue: PBOOL): HResult; stdcall;
    function GetWindowDesktopId(Wnd: HWND; pDesktopID: PGUID): HResult; stdcall;
    function MoveWindowToDesktop(Wnd: HWND; const DesktopID: TGUID): HResult; stdcall;
  end;

  TWindowInfo = (wiRect, wiText);
  TWindowInfos = set of TWindowInfo;

  TWindow = class
  public
    Handle: HWND;
    Rect: TRect;
    Text: string;
  end;

  TWindowList = TObjectList<TWindow>;

  TWindowRectFunction = reference to function(WindowHandle: HWND): TRect;
  TWindowStringFunction = reference to function(WindowHandle: HWND): string;

  TWindowEnumerator = class
  private
    FWorkList: TWindowList;
    FIncludeMask: NativeInt;
    FExcludeMask: NativeInt;
    FRequiredWindowInfos: TWindowInfos;
    FVirtualDesktopFilter: Boolean;
    FOverlappedWindowsFilter: Boolean;
    FVirtualDesktopAvailable: Boolean;
    FVirtualDesktopManager: IVirtualDesktopManager;
    FGetWindowRectFunction: TWindowRectFunction;
    FGetWindowTextFunction: TWindowStringFunction;

    procedure FilterVirtualDesktop;
    procedure FilterOverlappedWindows;
    procedure FillWindowInfos;

  public
    constructor Create;

    function GetWindowRect(WindowHandle: HWND): TRect;
    function GetWindowText(WindowHandle: HWND): string;

    function Enumerate: TWindowList;

    property IncludeMask: NativeInt read FIncludeMask write FIncludeMask;
    property ExcludeMask: NativeInt read FExcludeMask write FExcludeMask;
    property RequiredWindowInfos: TWindowInfos read FRequiredWindowInfos write FRequiredWindowInfos;
    property VirtualDesktopFilter: Boolean read FVirtualDesktopFilter write FVirtualDesktopFilter;
    property OverlappedWindowsFilter: Boolean read FOverlappedWindowsFilter write FOverlappedWindowsFilter;

    property GetWindowRectFunction: TWindowRectFunction read FGetWindowRectFunction write FGetWindowRectFunction;
    property GetWindowTextFunction: TWindowStringFunction read FGetWindowTextFunction write FGetWindowTextFunction;
  end;

implementation

function AddWindowToList(WindowHandle: THandle; Target: Pointer): Boolean; stdcall;
var
  WE: TWindowEnumerator absolute Target;
  Window: TWindow;
  WindowStyle: NativeInt;

  function HasStyle(CheckMask: FixedUInt): Boolean;
  begin
    Result := (WindowStyle and CheckMask) = CheckMask;
  end;

begin
  Result := True;
  WindowStyle := GetWindowLong(WindowHandle, GWL_STYLE);

  if (WE.ExcludeMask > 0) and HasStyle(WE.ExcludeMask) then
    Exit;

  if (WE.IncludeMask = 0) or HasStyle(WE.IncludeMask) then
  begin
    Window := TWindow.Create;
    try
      Window.Handle := WindowHandle;
      WE.FWorkList.Add(Window);
    except
      Window.Free;
      raise;
    end;
  end;
end;

{ TWindowEnumerator }

constructor TWindowEnumerator.Create;
begin
  FVirtualDesktopAvailable := TOSVersion.Check(6, 3); // Windows 10
  FGetWindowRectFunction := GetWindowRect;
  FGetWindowTextFunction := GetWindowText;
end;

procedure TWindowEnumerator.FilterVirtualDesktop;
var
  cc: Integer;
  WinOnCurrentDesktop: Boolean;
begin
  for cc := FWorkList.Count - 1 downto 0 do
    if Succeeded(FVirtualDesktopManager.IsWindowOnCurrentVirtualDesktop(FWorkList[cc].Handle, @WinOnCurrentDesktop)) and
      not WinOnCurrentDesktop then
      FWorkList.Delete(cc);
end;

procedure TWindowEnumerator.FilterOverlappedWindows;

  function IsWindowVisible(Handle: HWND; out Rect: TRect): Boolean;
  var
    Placement: TWindowPlacement;
  begin
    Rect := GetWindowRectFunction(Handle);
    Result := not Rect.IsEmpty and not IsIconic(Handle);
    if Result then
    begin
      Placement.length := SizeOf(TWindowPlacement);
      if GetWindowPlacement(Handle, Placement) and (Placement.showCmd = SW_SHOWMINIMIZED) then
        Result := False;
    end;
  end;

  // Inspired from <https://stackoverflow.com/questions/35240177/function-to-check-if-a-window-is-visible-on-screen-does-not-work-on-windows-7>
  function IsWindowEffectiveVisible(Index: Integer): Boolean;
  var
    cc: Integer;
    RefRect, TestRect: TRect;
    RefRegion, TestRegion: HRGN;
    CombineResult: Integer;
  begin
    Result := False;

    if not IsWindowVisible(FWorkList[Index].Handle, RefRect) then
      Exit;

    RefRegion := CreateRectRgnIndirect(RefRect);
    try
      for cc := Index - 1 downto 0 do
        if IsWindowVisible(FWorkList[cc].Handle, TestRect) then
        begin
          TestRegion := CreateRectRgnIndirect(TestRect);
          try
            CombineResult := CombineRgn(RefRegion, RefRegion, TestRegion, RGN_DIFF);
            if CombineResult = NULLREGION then
              Exit;
          finally
            DeleteObject(TestRegion);
          end;
        end;
    finally
      DeleteObject(RefRegion);
    end;

    Result := True;
  end;

var
  cc: Integer;
begin
  for cc := FWorkList.Count - 1 downto 1 do
    if not IsWindowEffectiveVisible(cc) then
      FWorkList.Delete(cc);
end;

procedure TWindowEnumerator.FillWindowInfos;
var
  Window: TWindow;
begin
  if FRequiredWindowInfos = [] then
    Exit;

  for Window in FWorkList do
  begin
    if wiRect in FRequiredWindowInfos then
      Window.Rect := GetWindowRectFunction(Window.Handle);
    if wiText in FRequiredWindowInfos then
      Window.Text := GetWindowTextFunction(Window.Handle);
  end;
end;

function TWindowEnumerator.GetWindowRect(WindowHandle: HWND): TRect;
begin
  if not Winapi.Windows.GetWindowRect(WindowHandle, Result) then
    Result := TRect.Empty;
end;

function TWindowEnumerator.GetWindowText(WindowHandle: HWND): string;
var
  TextLength: Integer;
begin
  TextLength := Winapi.Windows.GetWindowTextLength(WindowHandle);
  if TextLength > 0 then
  begin
    SetLength(Result, TextLength);
    Winapi.Windows.GetWindowText(WindowHandle, PChar(Result), TextLength + 1);
  end
  else
    Result := '';
end;

// Perform the window enumeration, apply the filters as configured and fill the infos
//
// Important: The returned list must be freed outside!
function TWindowEnumerator.Enumerate: TWindowList;
begin
  FWorkList := TWindowList.Create;
  Result := FWorkList;
  try
    try
      if not EnumWindows(@AddWindowToList, NativeInt(Self)) or (FWorkList.Count = 0) then
        Exit;

      if FVirtualDesktopFilter and FVirtualDesktopAvailable then
      begin
        if not Assigned(FVirtualDesktopManager) then
          FVirtualDesktopAvailable := Succeeded(CoCreateInstance(CLSID_VirtualDesktopManager, nil,
            CLSCTX_INPROC_SERVER, IID_VirtualDesktopManager, FVirtualDesktopManager));

        if FVirtualDesktopAvailable then
          FilterVirtualDesktop;
      end;
      if FOverlappedWindowsFilter then
        FilterOverlappedWindows;
      FillWindowInfos;
    except
      FWorkList.Free;
      raise;
    end;
  finally
    FWorkList := nil;
  end;
end;

end.
