unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.StrUtils,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Menus,
  Vcl.ComCtrls,

  WindowEnumerator;

type
  TMainForm = class(TForm)
    EnumerateButton: TButton;
    IncludeFilterPanel: TFlowPanel;
    FilterLabel: TLabel;
    ExcludeFilterPanel: TFlowPanel;
    EnumeratePanel: TPanel;
    Panel1: TPanel;
    AutoUpdateCheckBox: TCheckBox;
    AutoUpdateTimer: TTimer;
    OptionsPanel: TPanel;
    FilterOverlappedWindowsCheckBox: TCheckBox;
    OnlyCurrendVDCheckBox: TCheckBox;
    Label1: TLabel;
    FilterSelfCheckBox: TCheckBox;
    OptionsFlowPanel: TFlowPanel;
    FilterCloakedWindowsCheckBox: TCheckBox;
    FilterHiddenWindowsCheckBox: TCheckBox;
    FilterMonitorCheckBox: TCheckBox;
    FilterInactiveTopMostWindowsCheckBox: TCheckBox;
    MainList: TListView;
    procedure EnumerateButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AutoUpdateTimerTimer(Sender: TObject);
    procedure AutoUpdateCheckBoxClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MainListData(Sender: TObject; Item: TListItem);

  private
    FWinEnumerator: TWindowEnumerator;
    FSelectedWindow: HWND;
    FMainWinList: TWindowList;

    procedure AutoSizeFilterPanels;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);

  procedure AddFilterCheckBox(ConstantName: string; Mask: NativeUInt;
    CheckInclude: Boolean = False; CheckExclude: Boolean = False);

    function AddCheckBox(Parent: TWinControl; Tag: NativeInt): TCheckBox;
    begin
      Result := TCheckBox.Create(Self);
      Result.Parent := Parent;
      Result.Name := 'CB_' + Parent.Name + IntToStr(Parent.ControlCount);
      Result.Tag := Tag;
      Result.SetBounds(0, 0, MulDiv(165, Screen.PixelsPerInch, PixelsPerInch),
        MulDiv(17, Screen.PixelsPerInch, PixelsPerInch));
    end;

  var
    CB: TCheckBox;
  begin
    CB := AddCheckBox(IncludeFilterPanel, Mask);
    CB.Caption := 'Include ' + ConstantName;
    CB.Checked := CheckInclude;

    CB := AddCheckBox(ExcludeFilterPanel, Mask);
    CB.Caption := 'Exclude ' + ConstantName;
    CB.Checked := CheckExclude;
  end;

begin
  AddFilterCheckBox('WS_CAPTION', WS_CAPTION, True);
  AddFilterCheckBox('WS_DISABLED', WS_DISABLED, False, True);
  AddFilterCheckBox('WS_POPUP', WS_POPUP);
  AddFilterCheckBox('WS_SYSMENU', WS_SYSMENU);
  AddFilterCheckBox('WS_TILEDWINDOW', WS_TILEDWINDOW);
  AddFilterCheckBox('WS_VISIBLE', WS_VISIBLE, True);

  AutoSizeFilterPanels;

  FWinEnumerator := TWindowEnumerator.Create;
  FWinEnumerator.RequiredWindowInfos := [wiRect, wiText, wiClassName];

  AutoUpdateCheckBox.Checked := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FWinEnumerator.Free;
  FMainWinList.Free;
end;

procedure TMainForm.AutoUpdateCheckBoxClick(Sender: TObject);
begin
  AutoUpdateTimer.Enabled := AutoUpdateCheckBox.Checked;
end;

procedure TMainForm.AutoUpdateTimerTimer(Sender: TObject);
begin
  EnumerateButton.Click;
end;

procedure TMainForm.EnumerateButtonClick(Sender: TObject);

  function GetCheckedMask(ContainerPanel: TWinControl): NativeInt;
  var
    FilterControl: TControl;
    FilterCheckBox: TCheckBox absolute FilterControl;
    cc: Integer;
  begin
    Result := 0;
    for cc := 0 to ContainerPanel.ControlCount - 1 do
    begin
      FilterControl := ContainerPanel.Controls[cc];
      if (FilterControl is TCheckBox) and FilterCheckBox.Checked and (FilterCheckBox.Tag > 0) then
        Result := Result or FilterCheckBox.Tag;
    end;
  end;

var
  WinList: TWindowList;
begin
  FWinEnumerator.ExcludeMask := GetCheckedMask(ExcludeFilterPanel);
  FWinEnumerator.IncludeMask := GetCheckedMask(IncludeFilterPanel);
  FWinEnumerator.VirtualDesktopFilter := OnlyCurrendVDCheckBox.Checked;
  FWinEnumerator.HiddenWindowsFilter := FilterHiddenWindowsCheckBox.Checked;
  FWinEnumerator.OverlappedWindowsFilter := FilterOverlappedWindowsCheckBox.Checked;
  FWinEnumerator.CloakedWindowsFilter := FilterCloakedWindowsCheckBox.Checked;
  FWinEnumerator.MonitorFilter := FilterMonitorCheckBox.Checked;
  FWinEnumerator.InactiveTopMostWindowsFilter := FilterInactiveTopMostWindowsCheckBox.Checked;

  if MainList.ItemIndex >= 0 then
    FSelectedWindow := FMainWinList[MainList.ItemIndex].Handle;

  WinList := FWinEnumerator.Enumerate;

  if FilterSelfCheckBox.Checked then
    WinList.Remove(Handle);

  FMainWinList.Free;
  FMainWinList := WinList;
  MainList.Items.Count := FMainWinList.Count;
  MainList.Invalidate;

  if FSelectedWindow <> 0 then
    MainList.ItemIndex := FMainWinList.IndexOf(FSelectedWindow);

  Caption := Format('Matched windows: %d', [WinList.Count]);
end;

procedure TMainForm.AutoSizeFilterPanels;
begin
  ExcludeFilterPanel.AutoSize := True;
  ExcludeFilterPanel.AutoSize := False;
  IncludeFilterPanel.AutoSize := True;
  IncludeFilterPanel.AutoSize := False;
  OptionsFlowPanel.Left := 0;
  OptionsPanel.AutoSize := True;
  OptionsPanel.AutoSize := False;

  // The bottom order can be jumbled after AutoSize, so we must correct it
  FilterLabel.Top := MainList.Top + MainList.Height + 5;
  ExcludeFilterPanel.Top := FilterLabel.Top + FilterLabel.Height + 5;
  IncludeFilterPanel.Top := ExcludeFilterPanel.Top + ExcludeFilterPanel.Height + 5;
  OptionsPanel.Top := IncludeFilterPanel.Top + IncludeFilterPanel.Height + 5;
  EnumeratePanel.Top := OptionsPanel.Top + OptionsPanel.Height + 5;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  AutoSizeFilterPanels;
end;

procedure TMainForm.MainListData(Sender: TObject; Item: TListItem);
var
  Index: Integer;
  WI: TWindow;

  function GetWindowRectAsString: string;
  begin
    if WI.Rect.IsEmpty then
      Result := '(IsEmpty)'
    else
      Result := Format('%d, %d, %d, %d', [WI.Rect.Left, WI.Rect.Top, WI.Rect.Right, WI.Rect.Bottom]);
  end;

begin
  Index := Item.Index;
  if not (Assigned(FMainWinList) and (Index < FMainWinList.Count)) then
    Exit;

  WI := FMainWinList[Index];
  Item.Caption := IntToStr(WI.Handle);
  Item.SubItems.Add(GetWindowRectAsString);
  Item.SubItems.Add(IntToStr(GetDpiForWindow(WI.Handle)));
  Item.SubItems.Add(WI.Text);
  Item.SubItems.Add(WI.ClassName);
end;

end.
