
unit ThinIcoButton;

interface

uses
	Windows,
{$IFnDEF FPC}
	Messages,
{$ELSE}
	LCLIntf,
	LCLType,
{$ENDIF}
	Classes,
	Controls,
	Graphics,
	Buttons;





{$include 'mattes.inc'}





type
	TTextPosition = (tpTopLeft, tpTopCenter, tpTopRight, tpCenterLeft, tpCenterCenter, tpCenterRight, tpBottomLeft, tpBottomCenter, tpBottomRight, tpNone);

	// copied from Buttons.pas
	TGlyphList = class(TImageList)
	private
		Used: TBits;
		FCount: Integer;
		function AllocateIndex(): Integer;

	public
		constructor CreateSize(AWidth, AHeight: Integer);
		destructor Destroy(); override;
		function AddMasked(Image: TBitmap; MaskColor: TColor): Integer;
		procedure Delete(Index: Integer);

		property Count: Integer read FCount;
	end;

	TButtonGlyph = class
	private
		FOriginal: TBitmap;
		FGlyphList: TGlyphList;
		FIndexs: array[TButtonState] of Integer;
		FTransparentColor: TColor;
		FNumGlyphs: TNumGlyphs;
		FOnChange: TNotifyEvent;

		procedure GlyphChanged(Sender: TObject);
		procedure SetGlyph(Value: TBitmap);
		procedure SetNumGlyphs(Value: TNumGlyphs);
		procedure Invalidate();
		function CreateButtonGlyph(State: TButtonState): Integer;
		procedure DrawButtonGlyph(Canvas: TCanvas; const GlyphPos: TPoint; State: TButtonState; Transparent: Boolean);
		function fGetWidth(): integer;
		function fGetHeight(): integer;

	public
		constructor Create();
		destructor Destroy(); override;

		property Glyph: TBitmap read FOriginal write SetGlyph;
		property NumGlyphs: TNumGlyphs read FNumGlyphs write SetNumGlyphs;
		property OnChange: TNotifyEvent read FOnChange write FOnChange;
		property Height: integer read fGetHeight;
		property Width: integer read fGetWidth;
	end;

	TGlyphCache = class
	private
		GlyphLists: TList;

	public
		constructor Create();
		destructor Destroy(); override;
		function GetList(AWidth, AHeight: Integer): TGlyphList;
		procedure ReturnList(List: TGlyphList);
		function Empty(): Boolean;
	end;


	TThinIcoButton = class(TCustomControl)
	private
		fDown: boolean;
		fMouseDown: boolean;
		fMousePressing: boolean;
		fTextPosition: TTextPosition;
		fGlyph: TButtonGlyph;
		fDownColor: TColor;

		procedure fSetDown(newDown: boolean);
		procedure fSetTextPosition(newTextPosition: TTextPosition);
		procedure fSetDownColor(iVal: TColor);

		procedure GlyphChanged(Sender: TObject);
		function  GetGlyph: TBitmap;
		procedure SetGlyph(Value: TBitmap);
		function  GetNumGlyphs: TNumGlyphs;
		procedure SetNumGlyphs(Value: TNumGlyphs);

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
			destructor Destroy(); override;

	published
		constructor Create(aOwner: TComponent); override;

		property Down: boolean read fDown write fSetDown default False;
		property TextPosition: TTextPosition read fTextPosition write fSetTextPosition default tpCenterCenter;
		property DownColor: TColor read fDownColor write fSetDownColor default clBtnFace;

		// inherited properties:
		property Align;
		property Action;
		property Anchors;
		property BiDiMode;
		property Constraints;
		property Caption;
		property Enabled;
		property Font;
		property Glyph: TBitmap read GetGlyph write SetGlyph;
		property NumGlyphs: TNumGlyphs read GetNumGlyphs write SetNumGlyphs default 1;
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
	ThinIcoButton_DefaultDownColor: TColor;





















implementation

uses
	Forms,
	Types,
	SysUtils,
	CommCtrl;





{$IFDEF FPC}
function CopyPalette(Source: hPalette): hPalette;
var
	LP: ^TLogPalette;
	NumEntries: integer;
begin
	Result := 0;
	GetMem(LP, Sizeof(TLogPalette) + 256 * Sizeof(TPaletteEntry));
	try
		with LP^ do
		begin
			palVersion := $300;
			palNumEntries := 256;
			NumEntries := GetPaletteEntries(Source, 0, 256, palPalEntry);
			if NumEntries > 0 then
			begin
				palNumEntries := NumEntries;
				Result := CreatePalette(LP^);
			end;
		end;
	finally
		FreeMem(LP, Sizeof(TLogPalette) + 256 * Sizeof(TPaletteEntry));
	end;
end;
{$ENDIF}





procedure Register();
begin
	RegisterComponents(CONST_PAGE, [TThinIcoButton]);
end;





{ TGlyphList }

constructor TGlyphList.CreateSize(AWidth, AHeight: Integer);
begin
	inherited CreateSize(AWidth, AHeight);

	Used := TBits.Create;
end;





destructor TGlyphList.Destroy();
begin
	Used.Free();

	inherited Destroy();
end;





function TGlyphList.AllocateIndex(): Integer;
begin
	Result := Used.OpenBit;
	if Result >= Used.Size then
	begin
		Result := inherited Add(nil, nil);
		Used.Size := Result + 1;
	end;
	Used[Result] := True;
end;





function TGlyphList.AddMasked(Image: TBitmap; MaskColor: TColor): Integer;
begin
	Result := AllocateIndex;
	ReplaceMasked(Result, Image, MaskColor);
	Inc(FCount);
end;





procedure TGlyphList.Delete(Index: Integer);
begin
	if Used[Index] then
	begin
		Dec(FCount);
		Used[Index] := False;
	end;
end;





{ TGlyphCache }

constructor TGlyphCache.Create();
begin
	inherited Create();

	GlyphLists := TList.Create();
end;





destructor TGlyphCache.Destroy();
begin
	GlyphLists.Free();

	inherited Destroy();
end;





function TGlyphCache.GetList(AWidth, AHeight: Integer): TGlyphList;
var
	I: Integer;
begin
	for I := GlyphLists.Count - 1 downto 0 do
	begin
		Result := GlyphLists[I];
		with Result do
			if (AWidth = Width) and (AHeight = Height) then Exit;
	end;
	Result := TGlyphList.CreateSize(AWidth, AHeight);
	GlyphLists.Add(Result);
end;





procedure TGlyphCache.ReturnList(List: TGlyphList);
begin
	if List = nil then Exit;
	if List.Count = 0 then
	begin
		GlyphLists.Remove(List);
		List.Free();
	end;
end;





function TGlyphCache.Empty(): Boolean;
begin
	Result := GlyphLists.Count = 0;
end;





var
	GlyphCache: TGlyphCache = nil;
{$IFnDEF FPC}
	ButtonCount: Integer = 0;
{$ENDIF}





{ TButtonGlyph }

constructor TButtonGlyph.Create();
var
	I: TButtonState;
begin
	inherited Create();

	FOriginal := TBitmap.Create;
	FOriginal.OnChange := GlyphChanged;
	FTransparentColor := clOlive;
	FNumGlyphs := 1;
	for I := Low(I) to High(I) do
		FIndexs[I] := -1;

	if GlyphCache = nil then GlyphCache := TGlyphCache.Create;
end;





destructor TButtonGlyph.Destroy();
begin
	FOriginal.Free();
	Invalidate();
	if Assigned(GlyphCache) and GlyphCache.Empty() then
	begin
		GlyphCache.Free();
		GlyphCache := nil;
	end;

	inherited Destroy();
end;





procedure TButtonGlyph.Invalidate();
var
	I: TButtonState;
begin
	for I := Low(I) to High(I) do
	begin
		if FIndexs[I] <> -1 then FGlyphList.Delete(FIndexs[I]);
		FIndexs[I] := -1;
	end;
	GlyphCache.ReturnList(FGlyphList);
	FGlyphList := nil;
end;





procedure TButtonGlyph.GlyphChanged(Sender: TObject);
begin
	if Sender = FOriginal then
	begin
		FTransparentColor := FOriginal.TransparentColor;
		Invalidate();
		if Assigned(FOnChange) then FOnChange(Self);
	end;
end;





procedure TButtonGlyph.SetGlyph(Value: TBitmap);
var
	Glyphs: Integer;
begin
	Invalidate();
	FOriginal.Assign(Value);
	if (Value <> nil) and (Value.Height > 0) then
	begin
		FTransparentColor := Value.TransparentColor;
		if Value.Width mod Value.Height = 0 then
		begin
			Glyphs := Value.Width div Value.Height;
			if Glyphs > 4 then Glyphs := 1;
			SetNumGlyphs(Glyphs);
		end;
	end;
end;





procedure TButtonGlyph.SetNumGlyphs(Value: TNumGlyphs);
begin
	if (Value <> FNumGlyphs) and (Value > 0) then
	begin
		Invalidate();
		FNumGlyphs := Value;
		GlyphChanged(Glyph);
	end;
end;





function TButtonGlyph.CreateButtonGlyph(State: TButtonState): Integer;
const
	ROP_DSPDxax = $00e20746;
var
	TmpImage, DDB, MonoBmp: TBitmap;
	IWidth, IHeight: Integer;
	IRect, ORect: TRect;
	I: TButtonState;
	DestDC: HDC;
begin
	if (State = bsDown) and (NumGlyphs < 3) then State := bsUp;
	Result := FIndexs[State];
	if Result <> -1 then Exit;
	if (FOriginal.Width or FOriginal.Height) = 0 then Exit;
	IWidth := FOriginal.Width div FNumGlyphs;
	IHeight := FOriginal.Height;
	if FGlyphList = nil then
	begin
		if GlyphCache = nil then GlyphCache := TGlyphCache.Create;
		FGlyphList := GlyphCache.GetList(IWidth, IHeight);
	end;

	TmpImage := TBitmap.Create();
	try
		TmpImage.Width := IWidth;
		TmpImage.Height := IHeight;
		IRect := Rect(0, 0, IWidth, IHeight);
		TmpImage.Canvas.Brush.Color := clBtnFace;
		TmpImage.Palette := CopyPalette(FOriginal.Palette);
		I := State;
		if Ord(I) >= NumGlyphs then I := bsUp;
		ORect := Rect(Ord(I) * IWidth, 0, (Ord(I) + 1) * IWidth, IHeight);
		case State of
			bsUp, bsDown,
			bsExclusive:
			begin
				TmpImage.Canvas.CopyRect(IRect, FOriginal.Canvas, ORect);
				if FOriginal.TransparentMode = tmFixed then
					FIndexs[State] := FGlyphList.AddMasked(TmpImage, FTransparentColor)
				else
					FIndexs[State] := FGlyphList.AddMasked(TmpImage, clDefault);
			end;
			bsDisabled:
			begin
				MonoBmp := nil;
				DDB := nil;
				try
					MonoBmp := TBitmap.Create();
					DDB := TBitmap.Create();
					DDB.Assign(FOriginal);
					DDB.HandleType := bmDDB;
					if NumGlyphs > 1 then
					with TmpImage.Canvas do
					begin
						{ Change white & gray to clBtnHighlight and clBtnShadow }
						CopyRect(IRect, DDB.Canvas, ORect);
						MonoBmp.Monochrome := True;
						MonoBmp.Width := IWidth;
						MonoBmp.Height := IHeight;

						{ Convert white to clBtnHighlight }
						DDB.Canvas.Brush.Color := clWhite;
						MonoBmp.Canvas.CopyRect(IRect, DDB.Canvas, ORect);
						Brush.Color := clBtnHighlight;
						DestDC := Handle;
						SetTextColor(DestDC, clBlack);
						SetBkColor(DestDC, clWhite);
						BitBlt(DestDC, 0, 0, IWidth, IHeight,
							MonoBmp.Canvas.Handle, 0, 0, ROP_DSPDxax);

						{ Convert gray to clBtnShadow }
						DDB.Canvas.Brush.Color := clGray;
						MonoBmp.Canvas.CopyRect(IRect, DDB.Canvas, ORect);
						Brush.Color := clBtnShadow;
						DestDC := Handle;
						SetTextColor(DestDC, clBlack);
						SetBkColor(DestDC, clWhite);
						BitBlt(DestDC, 0, 0, IWidth, IHeight,
							MonoBmp.Canvas.Handle, 0, 0, ROP_DSPDxax);

						{ Convert transparent color to clBtnFace }
						DDB.Canvas.Brush.Color := ColorToRGB(FTransparentColor);
						MonoBmp.Canvas.CopyRect(IRect, DDB.Canvas, ORect);
						Brush.Color := clBtnFace;
						DestDC := Handle;
						SetTextColor(DestDC, clBlack);
						SetBkColor(DestDC, clWhite);
						BitBlt(DestDC, 0, 0, IWidth, IHeight,
							MonoBmp.Canvas.Handle, 0, 0, ROP_DSPDxax);
					end
					else
					begin
						{ Create a disabled version }
						with MonoBmp do
						begin
							Assign(FOriginal);
							HandleType := bmDDB;
							Canvas.Brush.Color := clBlack;
							Width := IWidth;
							if Monochrome then
							begin
								Canvas.Font.Color := clWhite;
								Monochrome := False;
								Canvas.Brush.Color := clWhite;
							end;
							Monochrome := True;
						end;
						with TmpImage.Canvas do
						begin
							Brush.Color := clBtnFace;
							FillRect(IRect);
							Brush.Color := clBtnHighlight;
							SetTextColor(Handle, clBlack);
							SetBkColor(Handle, clWhite);
							BitBlt(Handle, 1, 1, IWidth, IHeight,
								MonoBmp.Canvas.Handle, 0, 0, ROP_DSPDxax);
							Brush.Color := clBtnShadow;
							SetTextColor(Handle, clBlack);
							SetBkColor(Handle, clWhite);
							BitBlt(Handle, 0, 0, IWidth, IHeight,
								MonoBmp.Canvas.Handle, 0, 0, ROP_DSPDxax);
						end;
					end;
				finally
			DDB.Free();
			MonoBmp.Free();
		end;
		FIndexs[State] := FGlyphList.AddMasked(TmpImage, clDefault);
	end;
		end;
	finally
		TmpImage.Free();
	end;
	Result := FIndexs[State];
{$IFnDEF FPC}
	FOriginal.Dormant();
{$ENDIF}
end;





procedure TButtonGlyph.DrawButtonGlyph(Canvas: TCanvas; const GlyphPos: TPoint;
	State: TButtonState; Transparent: Boolean);
var
	Index: Integer;
begin
	if FOriginal = nil then Exit;
	if (FOriginal.Width = 0) or (FOriginal.Height = 0) then Exit;
	Index := CreateButtonGlyph(State);
	with GlyphPos do
		if Transparent or (State = bsExclusive) then
			ImageList_DrawEx(FGlyphList.Handle, Index, Canvas.Handle, X, Y, 0, 0,
				clNone, clNone, ILD_Transparent)
		else
			ImageList_DrawEx(FGlyphList.Handle, Index, Canvas.Handle, X, Y, 0, 0,
				ColorToRGB(clBtnFace), clNone, ILD_Normal);
end;





function TButtonGlyph.fGetWidth: integer;
begin
	Result := FOriginal.Width div fNumGlyphs;
end;





function TButtonGlyph.fGetHeight: integer;
begin
	Result := FOriginal.Height;
end;





{ TThinIcoButton }

constructor TThinIcoButton.Create(aOwner: TComponent);
begin
	inherited Create(aOwner);

	fDownColor := ThinIcoButton_DefaultDownColor;
	Down := False;
	TextPosition := tpCenterCenter;
	Width := 75;
	Height := 25;
	fGlyph := TButtonGlyph.Create;
	fGlyph.OnChange := GlyphChanged;
end;





destructor TThinIcoButton.Destroy();
begin
	fGlyph.Free();

	inherited Destroy();
end;





procedure TThinIcoButton.WMLButtonDown(var Message: TWMMouse);
begin
	fMouseDown := True;
	fMousePressing := True;
	SetCapture(Self.Handle);
	Invalidate;
	if Assigned(OnMouseDown) then OnMouseDown(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
end;





procedure TThinIcoButton.WMLButtonUp(var Message: TWMMouse);
var
	pnt: TPoint;
begin
	if fMouseDown then
	begin
		fMouseDown := False;
		ReleaseCapture;
		Invalidate;
		if not(fMousePressing) then Exit;
		fMousePressing := False;

		pnt.x := 0;
		pnt.y := 0;
		GetCursorPos(pnt);
		pnt := ScreenToClient(pnt);
		if (pnt.x < 0) or (pnt.x > Width) then Exit;
		if (pnt.y < 0) or (pnt.y > Height) then Exit;

		if Assigned(OnMouseUp) then OnMouseUp(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
		if Assigned(OnClick) then OnClick(Self);
	end;
end;





procedure TThinIcoButton.WMLButtonDblClick(var Message: TWMMouse);
begin
	fMouseDown := True;
	fMousePressing := True;
	SetCapture(Self.Handle);
	Invalidate();
	if Assigned(OnDblClick) then OnDblClick(Self);
	if Assigned(OnMouseDown) then OnMouseDown(Self, mbLeft, KeysToShiftState(Message.Keys), Message.XPos, Message.YPos);
end;





procedure TThinIcoButton.WMMouseMove(var Message: TWMMouse);
var
	nmp: boolean;
begin
	if not(fMouseDown) then Exit;
	nmp := (Message.XPos >= 0) and (Message.XPos < ClientWidth) and (Message.YPos >= 0) and (Message.YPos < ClientHeight);
	if nmp <> fMousePressing then
	begin
		fMousePressing := nmp;
		Invalidate();
	end;
end;





procedure TThinIcoButton.fSetDown(newDown: boolean);
begin
	fDown := newDown;
	Invalidate();
end;





procedure TThinIcoButton.fSetDownColor(iVal: TColor);
begin
	if iVal = fDownColor then
	begin
		Exit;
	end;
	fDownColor := iVal;
	Invalidate();
end;





procedure TThinIcoButton.Paint();
var
	r: TRect;
	Frame: cardinal;
	txt: string;
	DC: HDC;
	l, tx, ty: integer;
	size: TSize;
	gp: TPoint;
begin
	r := Rect(0, 0, ClientWidth, ClientHeight);
	if (fDown xor fMousePressing) then Frame := BDR_SUNKENOUTER else Frame := BDR_RAISEDINNER;
	if fDown then Canvas.Brush.Color := DownColor else Canvas.Brush.Color := clBtnFace;
	Canvas.FillRect(r);
	DrawEdge(Canvas.Handle, r, Frame, BF_RECT);
	InflateRect(r, -1, -1);
	DC := Canvas.Handle;
	txt := Caption;
	Canvas.Font := Self.Font;

	if (trim(txt) = '') or (fTextPosition = tpNone) then
	begin
		case fTextPosition of
			tpTopCenter, tpCenterCenter, tpBottomCenter: gp.x := (r.Left + r.Right - fGlyph.Width) div 2;
			tpTopRight, tpCenterRight, tpBottomRight: gp.x := r.Right - fGlyph.Width - 4;
			else gp.x := 4;
		end;
		case fTextPosition of
			tpTopLeft, tpTopCenter, tpTopRight: gp.y := r.Top + 2;
			tpCenterRight, tpCenterCenter, tpCenterLeft: gp.y := (r.Top + r.Bottom - fGlyph.Height) div 2;
			else gp.y := r.Bottom - 2 - fGlyph.Height;
		end;

		if Enabled then
		begin
			fGlyph.DrawButtonGlyph(Canvas, gp, bsUp, True);
		end
		else
		begin
			fGlyph.DrawButtonGlyph(Canvas, gp, bsDisabled, True);
		end;
		Exit;
	end;

	l := length(txt);
	size.cx := 0;
	size.cy := 0;
	GetTextExtentPoint(DC, @txt[1], l, size);
	size.cx := size.cx + fGlyph.Width + 4;		// add glyph's size
	// if (Size.cy < fGlyph.Height) then Size.cy := fGlyph.Height;

	case fTextPosition of
		tpTopCenter, tpCenterCenter, tpBottomCenter: tx := (r.Left + r.Right - size.cx) div 2;
		tpTopRight, tpCenterRight, tpBottomRight: tx := r.Right - size.cx - 4;
		else tx := 4;
	end;
	case fTextPosition of
		tpTopLeft, tpTopCenter, tpTopRight:
		begin
			ty := 2;
			gp.y := r.Top + 2;
		end;
		tpCenterRight, tpCenterCenter, tpCenterLeft:
		begin
			ty := (r.Top + r.Bottom - size.cy) div 2;
			gp.y := (r.Top + r.Bottom - fGlyph.Height) div 2;
		end;
		tpBottomLeft, tpBottomCenter, tpBottomRight:
		begin
			ty := r.Bottom - size.cy - 3;
			gp.y := r.Bottom - 2 - fGlyph.Height;
		end;
		else
		begin
			ty := 4;
		end;
	end;

	gp.x := tx;
	tx := tx + fGlyph.Width + 4;

	SetBkMode(DC, TRANSPARENT);
	SetTextAlign(DC, TA_TOP or TA_LEFT);
	if Enabled then
	begin
		r.Left := tx;
		SetTextColor(DC, GetSysColor(COLOR_BTNTEXT));
		r.Top := ty;
		DrawText(DC, @txt[1], l, r, DT_TOP or DT_LEFT);
		fGlyph.DrawButtonGlyph(Canvas, gp, bsUp, True);
	end
	else
	begin
		r.Left := tx + 1;
		SetTextColor(DC, GetSysColor(COLOR_3DHILIGHT));
		r.Top := ty + 1;
		DrawText(DC, @txt[1], l, r, DT_TOP or DT_LEFT);
		r.Left := tx;
		SetTextColor(DC, GetSysColor(COLOR_BTNSHADOW));
		r.Top := ty;
		DrawText(DC, @txt[1], l, r, DT_TOP or DT_LEFT);
		fGlyph.DrawButtonGlyph(Canvas, gp, bsDisabled, True);
	end;
end;





procedure TThinIcoButton.fSetTextPosition(newTextPosition: TTextPosition);
begin
	fTextPosition := newTextPosition;
	Invalidate();
end;





procedure TThinIcoButton.GlyphChanged(Sender: TObject);
var
	ng: integer;
begin
	ng := 1;
	if Glyph.Height > 0 then ng := Glyph.Width div Glyph.Height;
	if (ng < 1) then ng := 1;
	NumGlyphs := ng;
	Invalidate();
end;





function TThinIcoButton.GetGlyph(): TBitmap;
begin
	Result := TButtonGlyph(FGlyph).Glyph;
end;





procedure TThinIcoButton.SetGlyph(Value: TBitmap);
begin
	TButtonGlyph(FGlyph).Glyph := Value;
	Invalidate();
end;





function TThinIcoButton.GetNumGlyphs: TNumGlyphs;
begin
	Result := TButtonGlyph(FGlyph).NumGlyphs;
end;





procedure TThinIcoButton.SetNumGlyphs(Value: TNumGlyphs);
begin
	if Value <= Low(TNumGlyphs) then Value := Low(TNumGlyphs)
	else if Value >= High(TNumGlyphs) then Value := High(TNumGlyphs);
	if Value <> TButtonGlyph(FGlyph).NumGlyphs then
	begin
		TButtonGlyph(FGlyph).NumGlyphs := Value;
		Invalidate();
	end;
end;





procedure TThinIcoButton.CMTextChanged(var Message: TMessage);
begin
	Invalidate();
end;





procedure TThinIcoButton.CMDialogChar(var Message: TCMDialogChar);
begin
	if Enabled and Assigned(OnClick) and IsAccel(Message.CharCode, Caption) then
	begin
		OnClick(Self);
		Message.Result := 1;
	end;
end;





procedure TThinIcoButton.SetEnabled(Value: Boolean);
begin
	inherited SetEnabled(Value);

	Invalidate();
end;





initialization
	ThinIcoButton_DefaultDownColor := RGB($cf, $ff, $cf);





end.








