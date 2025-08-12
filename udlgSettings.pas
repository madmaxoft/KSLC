unit udlgSettings;

interface

uses
	Windows,
	Messages,
	SysUtils,
	Variants,
	Classes,
	Graphics,
	Controls,
	Forms,
	Dialogs,
	ThinIcoButton,
	ExtCtrls,
	StdCtrls;




	
type
  TdlgSettings = class(TForm)
    pGameFolder: TPanel;
    pTl: TPanel;
    tlOK: TThinIcoButton;
    tlCancel: TThinIcoButton;
    Label1: TLabel;
    eKSDir: TEdit;
    tlBrowseKSDir: TThinIcoButton;
    pWebUpdate: TPanel;
    Label2: TLabel;
    chbAllowWebVersionCheck: TCheckBox;
    chbAllowWebStats: TCheckBox;
    mStatPlea: TMemo;
    procedure tlOKClick(Sender: TObject);
    procedure tlCancelClick(Sender: TObject);
    procedure tlBrowseKSDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure chbAllowWebVersionCheckClick(Sender: TObject);
	end;





implementation

uses
	uKSLog,
	uSettings,
	ufrmMain,
	uKSRepresentations;





{$R *.dfm}





procedure TdlgSettings.tlOKClick(Sender: TObject);
begin
	gKSDir := eKSDir.Text;
	if (gKSDir[Length(gKSDir)] <> '\') then
	begin
		gKSDir := gKSDir + '\';
	end;
	gLog.Log(LOG_INFO, 'Knytt Stories directory set to "' + gKSDir + '"');
	gSettings.AllowWebVersionCheck := chbAllowWebVersionCheck.Checked;
	gSettings.AllowWebStats := chbAllowWebStats.Checked;
	ModalResult := mrOK;
end;





procedure TdlgSettings.tlCancelClick(Sender: TObject);
begin
	ModalResult := mrCancel;
end;




procedure TdlgSettings.tlBrowseKSDirClick(Sender: TObject);
var
	dlgOpen: TOpenDialog;
begin
	dlgOpen := TOpenDialog.Create(Self);
	try
			dlgOpen.InitialDir := '.';
			dlgOpen.Title := 'Where is your Knytt Stories exe:';
			dlgOpen.Filter := 'Knytt Stories Executable|Knytt Stories.exe';
			if (dlgOpen.Execute()) then
			begin
				eKSDir.Text := ExtractFilePath(dlgOpen.Filename);
				if (eKSDir.Text[Length(eKSDir.Text)] <> '\') then
				begin
					eKSDir.Text := eKSDir.Text + '\';
				end;
			end
	finally
		dlgOpen.Free();
	end;
end;





procedure TdlgSettings.FormCreate(Sender: TObject);
begin
	eKSDir.Text := gKSDir;
	chbAllowWebVersionCheck.Checked := gSettings.AllowWebVersionCheck;
	chbAllowWebVersionCheckClick(Sender);
	chbAllowWebStats.Checked := gSettings.AllowWebStats;

	tlOK.Glyph.LoadFromResourceName(HInstance, 'BBOK');
	tlCancel.Glyph.LoadFromResourceName(HInstance, 'BBCANCEL');
end;





procedure TdlgSettings.chbAllowWebVersionCheckClick(Sender: TObject);
begin
	// Only allow webstats when webcheck is enabled:
	chbAllowWebStats.Enabled := chbAllowWebVersionCheck.Checked;
	chbAllowWebStats.Checked := chbAllowWebStats.Checked and chbAllowWebStats.Enabled;
end;





end.
