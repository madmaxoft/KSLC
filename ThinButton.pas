
unit ThinButton;

interface

uses
{$IFnDEF FPC}
	Windows,
{$ENDIF}
	Messages,
	Classes,
	Controls,
	Graphics;

{$include 'mattes.inc'}





type
	TTextPosition = (tpTopLeft, tpTopCenter, tpTopRight, tpCenterLeft, tpCenterCenter, tpCenterRight, tpBottomLeft, tpBottomCenter, tpBottomRight);

	TThinButton = class(TCustomControl)
	private
		fDown: boolean;
		fMouseDown: boolean;
		fMousePressing: boolean;
		fTextPosition: TTextPosition;

		procedure fSetDown(newDown: boolean);
		procedure fSetTextPosition(newTextPosition: TTextPosition);

		// message-handling:
		procedure WMLButtonDown(var Message: TWMMouse); message WM_LBUTTONDOWN;
		procedure WMLButtonUp(var Message: TWMMouse); message WM_LBUTTONUP;
		procedure WMLButtonDblClick(var Message: TWMMouse); message WM_LBUTTONDBLCLK;
		procedure WMMouseMove(var Message: TWMMouse); message WM_MOUSEMOVE;
		procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
		procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;

	protected
		procedure Paint(); override;

		// overriding base functions:
		procedure SetEnabled(Value: Boolean); override;

		public
			destructor Destroy; override;

	published
		constructor Create(aOwner: TComponent); override;

		property Down: boolean read fDown write fSetDown default False;
		property TextPosition: TTextPosition read fTextPosition write fSetTextPosition default tpCenterCenter;

		// inherited properties:
		property Align;
		property Action;
		property Anchors;
		property BiDiMode;
		property Constraints;
		property Caption;
		property Enabled;
		property Font;
		property ParentFont;
		property ParentShowHint;
		property ParentBiDiMode;
		property PopupMenu;
		property ShowHint;
		property Visible;

		property OnClick;
		property OnDblClick;
		property OnMouseDown;
		property OnMouseMove;
		property OnMouseUp;
	end;





procedure Register();





var
	ThinButton_DownColor: TColor;





















implementation

uses
{$IFDEF FPC}
	LCLType,
	LCLIntf,
{$ENDIF}
	Forms;





procedure Register;
begin
	RegisterComponents(CONST_PAGE, [TThinButton]);
end;





{ TThinButton }

constructor TThinButton.Create(aOwner: TComponent);
begin
	inherited Create(aOwner);

	Down := False;
	TextPosition := tpCenterCenter;
	Width := 75;
	Height := 25;
end;





destructor TThinButton.Destroy;
begin
	inherited Destroy();
end;





procedure TThinButton.WMLButtonDown(var Message: TWMMouse);
begin
	fMouseDown := True;
	fMousePressing := True;
	SetCapture(Self.Handle);
	Invalidate();
	if Assigned(OnMouseDown) then OnMouseDown(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
end;





procedure TThinButton.WMLButtonUp(var Message: TWMMouse);
begin
	if fMouseDown then
	begin
		fMouseDown := False;
		fMousePressing := False;
		ReleaseCapture;
		Invalidate();
		if Assigned(OnMouseUp) then OnMouseUp(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
		if Assigned(OnClick) then OnClick(Self);
	end;
end;





procedure TThinButton.WMLButtonDblClick(var Message: TWMMouse);
begin
	fMouseDown := True;
	fMousePressing := True;
	SetCapture(Self.Handle);
	Invalidate();
	if Assigned(OnDblClick) then OnDblClick(Self);
	if Assigned(OnMouseDown) then OnMouseDown(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
end;





procedure TThinButton.WMMouseMove(var Message: TWMMouse);
var
	nmp: boolean;
	tempPoint: TPoint;
begin
{$IFnDEF FPC}
	tempPoint := CalcCursorPos();
{$ELSE}
	tempPoint.x := 0;
	tempPoint.y := 0;
	GetCursorPos(tempPoint);
	tempPoint := ScreenToClient(tempPoint);
{$ENDIF}
	with tempPoint do MouseMove(KeysToShiftState(Message.Keys), X, Y);

	if not(fMouseDown) then Exit;
	nmp := (Message.XPos >= 0) and (Message.XPos < ClientWidth) and (Message.YPos >= 0) and (Message.YPos < ClientHeight);
	if (nmp <> fMousePressing) then
	begin
		fMousePressing := nmp;
		Invalidate();
	end;
end;





procedure TThinButton.fSetDown(newDown: boolean);
begin
	fDown := newDown;
	Invalidate();
end;





procedure TThinButton.Paint();
var
	r: TRect;
	Frame: cardinal;
	txt: string;
	ta: Cardinal;
	DC: HDC;
begin
	r := Rect(0, 0, ClientWidth, ClientHeight);
	if (fDown xor fMousePressing) then Frame := BDR_SUNKENOUTER else Frame := BDR_RAISEDINNER;
	if fDown then Canvas.Brush.Color := ThinButton_DownColor else Canvas.Brush.Color := clBtnFace;
	DrawEdge(Canvas.Handle, r, Frame, BF_RECT or BF_MIDDLE);
	InflateRect(r, -1, -1);
	(*
	txt := Caption;
	tw := Canvas.TextWidth(txt);
	th := Canvas.TextHeight(txt);
	case fTextPosition of
		tpTopCenter, tpCenterCenter, tpBottomCenter: l := (ClientWidth - tw) shr 1;
		tpTopRight, tpCenterRight, tpBottomRight: l := ClientWidth - 2 - tw;
		else l := 2;
	end;
	case fTextPosition of
		tpTopLeft, tpTopCenter, tpTopRight: t := 2;
		tpCenterRight, tpCenterCenter, tpCenterLeft: t := (ClientHeight - th) shr 1;
		else t := ClientHeight - 2 - th;
	end;
	*)
	case fTextPosition of
		tpTopCenter, tpCenterCenter, tpBottomCenter: ta := DT_CENTER;
		tpTopRight, tpCenterRight, tpBottomRight: ta := DT_RIGHT;
		else ta := DT_LEFT;
	end;
	case fTextPosition of
		tpTopLeft, tpTopCenter, tpTopRight: ta := ta or DT_TOP;
		tpCenterRight, tpCenterCenter, tpCenterLeft: ta := ta or DT_VCENTER;
		else ta := ta or DT_BOTTOM;
	end;

	txt := Caption;
	DC := Canvas.Handle;
	if Enabled then
	begin
		SetBkMode(DC, TRANSPARENT);
		SetTextColor(DC, ColorToRGB(Font.Color));
		DrawText(DC, @txt[1], length(txt), r, DT_SINGLELINE or ta);
	end
	else
	begin
		SetBkMode(DC, TRANSPARENT);
		SetTextColor(DC, GetSysColor(COLOR_3DHILIGHT));
		DrawText(DC, @txt[1], length(txt), r, DT_SINGLELINE or ta);
		r.Top := r.Top - 1;
		r.Left := r.Left - 1;
		r.Right := r.Right - 1;
		r.Bottom := r.Bottom - 1;
		SetTextColor(DC, GetSysColor(COLOR_BTNSHADOW));
		DrawText(DC, @txt[1], length(txt), r, DT_SINGLELINE or ta);
	end;
end;





procedure TThinButton.fSetTextPosition(newTextPosition: TTextPosition);
begin
	fTextPosition := newTextPosition;
	Invalidate();
end;





procedure TThinButton.CMTextChanged(var Message: TMessage);
begin
	Invalidate();
end;





procedure TThinButton.CMDialogChar(var Message: TCMDialogChar);
begin
	if Assigned(OnClick) and IsAccel(Message.CharCode, Caption) then
	begin
		OnClick(Self);
		Message.Result := 1;
	end;
end;





procedure TThinButton.SetEnabled(Value: Boolean);
begin
	inherited SetEnabled(Value);
	Invalidate();
end;





initialization
	ThinButton_DownColor := RGB($cf, $ff, $cf);





end.
