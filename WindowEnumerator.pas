unit WindowEnumerator;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
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

  TWindow = class
  public
    Handle: HWND;
    Rect: TRect;
    Text: string;
  end;

  TWindowList = TObjectList<TWindow>;

  TWindowEnumerator = class
  private
    FWorkList: TWindowList;
    FIncludeMask: NativeInt;
    FExcludeMask: NativeInt;
    FVirtualDesktopFilter: Boolean;
    FOverlappedWindowsFilter: Boolean;
    FVirtualDesktopAvailable: Boolean;
    FVirtualDesktopManager: IVirtualDesktopManager;

    procedure FilterVirtualDesktop;
    procedure FilterOverlappedWindows;
    procedure FillWindowInfos;

  public
    constructor Create;

    function Enumerate: TWindowList;

    property IncludeMask: NativeInt read FIncludeMask write FIncludeMask;
    property ExcludeMask: NativeInt read FExcludeMask write FExcludeMask;
    property VirtualDesktopFilter: Boolean read FVirtualDesktopFilter write FVirtualDesktopFilter;
    property OverlappedWindowsFilter: Boolean read FOverlappedWindowsFilter write FOverlappedWindowsFilter;
  end;

implementation

function AddWindowToList(WindowHandle: THandle; Target: Pointer): Boolean; stdcall;
var
  WE: TWindowEnumerator absolute Target;
  WindowStyle: NativeInt;

  function HasStyle(CheckMask: FixedUInt): Boolean;
  begin
    Result := (WindowStyle and CheckMask) = CheckMask;
  end;

var
  Window: TWindow;
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

  function IsWindowEffectiveVisible(Index: Integer): Boolean;
  var
    cc: Integer;
    RefHandle, TestHandle: HWND;
    RefRect, TestRect: TRect;
    RefRegion, TestRegion: HRGN;
    CombineResult: Integer;
  begin
    Result := False;
    RefHandle := FWorkList[Index].Handle;

    if not Winapi.Windows.GetWindowRect(RefHandle, RefRect) and RefRect.IsEmpty then
      Exit;

    RefRegion := CreateRectRgnIndirect(RefRect);
    try
      for cc := Index - 1 downto 0 do
      begin
        TestHandle := FWorkList[cc].Handle;
        if not IsIconic(TestHandle) and Winapi.Windows.GetWindowRect(TestHandle, TestRect) and
          not TestRect.IsEmpty then
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

  function GetWindowText: string;
  var
    TextLength: Integer;
  begin
    TextLength := Winapi.Windows.GetWindowTextLength(Window.Handle);
    if TextLength > 0 then
    begin
      SetLength(Result, TextLength);
      Winapi.Windows.GetWindowText(Window.Handle, PChar(Result), TextLength + 1);
    end
    else
      Result := '';
  end;

begin
  for Window in FWorkList do
  begin
    Window.Text := GetWindowText;
    Winapi.Windows.GetWindowRect(Window.Handle, Window.Rect);
  end;
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
