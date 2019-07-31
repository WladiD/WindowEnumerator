unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Menus,
  WindowEnumerator;

type
  TMainForm = class(TForm)
    MainListBox: TListBox;
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
    procedure EnumerateButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AutoUpdateTimerTimer(Sender: TObject);
    procedure AutoUpdateCheckBoxClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    FWinEnumerator: TWindowEnumerator;

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
  AddFilterCheckBox('WS_CHILD', WS_CHILD);
  AddFilterCheckBox('WS_DISABLED', WS_DISABLED, False, True);
  AddFilterCheckBox('WS_POPUP', WS_POPUP);
  AddFilterCheckBox('WS_SYSMENU', WS_SYSMENU);
  AddFilterCheckBox('WS_TILEDWINDOW', WS_TILEDWINDOW);
  AddFilterCheckBox('WS_VISIBLE', WS_VISIBLE, True);

  AutoSizeFilterPanels;

  FWinEnumerator := TWindowEnumerator.Create;
  FWinEnumerator.RequiredWindowInfos := [wiRect, wiText];

  AutoUpdateCheckBox.Checked := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FWinEnumerator.Free;
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

  function CreateStringsFromWindowList(WindowList: TWindowList): TStrings;
  var
    WI: TWindow;

    function GetWindowRectAsString: string;
    begin
      if WI.Rect.IsEmpty then
        Result := '(IsEmpty)'
      else
        Result := Format('%d, %d, %d, %d', [WI.Rect.Left, WI.Rect.Top, WI.Rect.Right, WI.Rect.Bottom]);
    end;

  begin
    Result := TStringList.Create;
    try
      for WI in WindowList do
        Result.AddObject(Format('Handle: %d; Rect: %s; Text: %s',
          [WI.Handle, GetWindowRectAsString, WI.Text]), TObject(WI.Handle));
    except
      Result.Free;
      raise;
    end;
  end;

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
  SelHandle: TObject;
  WinList: TWindowList;
  WinStrings: TStrings;
begin
  WinStrings := nil;
  try
    FWinEnumerator.ExcludeMask := GetCheckedMask(ExcludeFilterPanel);
    FWinEnumerator.IncludeMask := GetCheckedMask(IncludeFilterPanel);
    FWinEnumerator.VirtualDesktopFilter := OnlyCurrendVDCheckBox.Checked;
    FWinEnumerator.OverlappedWindowsFilter := FilterOverlappedWindowsCheckBox.Checked;

    if MainListBox.ItemIndex >= 0 then
      SelHandle := MainListBox.Items.Objects[MainListBox.ItemIndex]
    else
      SelHandle := nil;

    WinList := FWinEnumerator.Enumerate;
    try
      WinStrings := CreateStringsFromWindowList(WinList);
    finally
      WinList.Free;
    end;

    if WinStrings.Equals(MainListBox.Items) then
      Exit;

    MainListBox.Items.Assign(WinStrings);

    if Assigned(SelHandle) then
      MainListBox.ItemIndex := MainListBox.Items.IndexOfObject(SelHandle);

    Caption := Format('Matched windows: %d', [WinStrings.Count]);
  finally
    WinStrings.Free;
  end;
end;

procedure TMainForm.AutoSizeFilterPanels;
begin
  ExcludeFilterPanel.AutoSize := True;
  ExcludeFilterPanel.AutoSize := False;
  IncludeFilterPanel.AutoSize := True;
  IncludeFilterPanel.AutoSize := False;

  // The bottom order can be jumbled after AutoSize, so we must correct it
  FilterLabel.Top := MainListBox.Top + MainListBox.Height + 5;
  ExcludeFilterPanel.Top := FilterLabel.Top + FilterLabel.Height + 5;
  IncludeFilterPanel.Top := ExcludeFilterPanel.Top + ExcludeFilterPanel.Height + 5;
  OptionsPanel.Top := IncludeFilterPanel.Top + IncludeFilterPanel.Height + 5;
  EnumeratePanel.Top := OptionsPanel.Top + OptionsPanel.Height + 5;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  AutoSizeFilterPanels;
end;

end.
