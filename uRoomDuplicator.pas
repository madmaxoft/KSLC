
unit uRoomDuplicator;

interface

uses
	Classes,
	uKSRepresentations,
	uKSObjects;





type
	TRoomDuplicatorSettings = class
	public
		ModifyRelativeContainedShifts: boolean;
		ModifyAbsoluteContainedShifts: boolean;
		ModifyContainedWarps: boolean;
		ModifyRelativeOutgoingShifts: boolean;
		ModifyAbsoluteOutgoingShifts: boolean;
		ModifyOutgoingWarps: boolean;

		constructor Create();

		function ShouldModifyShift(iIsAbsolute, iIsOutgoing: boolean): boolean;
		function ShouldModifyWarp(iIsContained: boolean): boolean;
	end;

	TRoomDuplicator = class
	public
		Level: TKSLevel;
		Selection: TList;
		SelectionOnly: boolean;

		constructor Create(iLevel: TKSLevel; iSelection: TList; iSelectionOnly: boolean);

		procedure Duplicate(iOffsetX, iOffsetY: integer; iSettings: TRoomDuplicatorSettings);		// copies the level, room by room
		function  Check    (iOffsetX, iOffsetY: integer): boolean;		// returns true if offset is ok for copying
		procedure Guess    (var oOffsetX, oOffsetY: integer);
		procedure ApplySettings(iDstRoom, iSrcRoom: TKSRoom; iSettings: TRoomDuplicatorSettings);

	protected
		function IsRoomInSrc(iRoomX, iRoomY: integer): boolean; overload;
		function IsRoomInSrc(iRoom: TKSRoom): boolean; overload;
		procedure ApplySettingsWarps(iSrcRoom, iDstRoom: TKSRoom; iSettings: TRoomDuplicatorSettings);

	end;














implementation

uses
	SysUtils;





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TRoomDuplicatorSettings:

constructor TRoomDuplicatorSettings.Create();
begin
	ModifyRelativeContainedShifts := false;
	ModifyAbsoluteContainedShifts := true;
	ModifyContainedWarps          := true;		// these are always absolute
	ModifyRelativeOutgoingShifts  := true;
	ModifyAbsoluteOutgoingShifts  := false;
	ModifyOutgoingWarps           := false;
end;





function TRoomDuplicatorSettings.ShouldModifyShift(iIsAbsolute, iIsOutgoing: boolean): boolean;
begin
	if (iIsOutgoing) then
	begin
		// The shift is outgoing:
		if (iIsAbsolute) then
		begin
			// Absolute outgoing shift
			Result := ModifyAbsoluteOutgoingShifts;
		end
		else
		begin
			// Relative outgoing shift
			Result := ModifyRelativeOutgoingShifts;
		end;
	end
	else
	begin
		// The shift is contained
		if (iIsAbsolute) then
		begin
			// Absolute shift
			Result := ModifyAbsoluteContainedShifts;
		end
		else
		begin
			// Relative shift
			Result := ModifyRelativeContainedShifts;
		end;
	end;
end;





function TRoomDuplicatorSettings.ShouldModifyWarp(iIsContained: boolean): boolean;
begin
	if (iIsContained) then
	begin
		Result := ModifyContainedWarps;
	end
	else
	begin
		Result := ModifyOutgoingWarps;
	end;
end;





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TRoomDuplicator:

constructor TRoomDuplicator.Create(iLevel: TKSLevel; iSelection: TList; iSelectionOnly: boolean);
begin
	inherited Create();
	Level := iLevel;
	Selection := iSelection;
	SelectionOnly := iSelectionOnly;
end;





procedure TRoomDuplicator.Duplicate(iOffsetX, iOffsetY: integer; iSettings: TRoomDuplicatorSettings);
var
	i: integer;
	r: TKSRoom;
begin
	if (SelectionOnly) then
	begin
		for i := 0 to Selection.Count - 1 do
		begin
			r := TKSRoom(Selection[i]);
			r := Level.AddRoom(r.XPos + iOffsetX, r.YPos + iOffsetY, @r.Data);
			r.CopyEventParamsFrom(TKSRoom(Selection[i]));
			r.UpdateFromData();
			ApplySettings(r, TKSRoom(Selection[i]), iSettings);
		end;		// for i
	end
	else
	begin
		for i := 0 to Level.NumRooms - 1 do
		begin
			r := Level.Room[i];
			r := Level.AddRoom(r.XPos + iOffsetX, r.YPos + iOffsetY, @r.Data);
			r.CopyEventParamsFrom(Level.Room[i]);
			r.UpdateFromData();
			ApplySettings(r, Level.Room[i], iSettings);
		end;		// for i
	end;
	Level.Changed();
end;





function TRoomDuplicator.Check(iOffsetX, iOffsetY: integer): boolean;
var
	i, j: integer;
	xp, yp: integer;
	r: TKSRoom;
begin
	if (SelectionOnly) then
	begin
		for i := 0 to Selection.Count - 1 do
		begin
			r := TKSRoom(Selection[i]);
			xp := r.XPos + iOffsetX;
			yp := r.YPos + iOffsetY;
			for j := 0 to Level.NumRooms - 1 do
			begin
				if ((xp = Level.Room[j].XPos) and (yp = Level.Room[j].YPos)) then
				begin
					Result := false;
					Exit;
				end;
			end;
		end;		// for i
	end
	else
	begin
		for i := 0 to Level.NumRooms - 1 do
		begin
			r := TKSRoom(Level.Room[i]);
			xp := r.XPos + iOffsetX;
			yp := r.YPos + iOffsetY;
			for j := 0 to Level.NumRooms - 1 do
			begin
				if ((xp = Level.Room[j].XPos) and (yp = Level.Room[j].YPos)) then
				begin
					Result := false;
					Exit;
				end;
			end;
		end;		// for i
	end;
	Result := true;		// is OK
end;





procedure TRoomDuplicator.Guess(var oOffsetX, oOffsetY: integer);
var
	i: integer;
	mxy, mny: integer;
begin
	if (Level.NumRooms <= 0) then
	begin
		oOffsetX := 0;
		oOffsetY := 0;
		Exit;
	end;
	mxy := Level.Room[0].YPos;
	mny := mxy;
	for i := 0 to Level.NumRooms - 1 do
	begin
		if (Level.Room[i].YPos < mny) then mny := Level.Room[i].YPos;
		if (Level.Room[i].YPos > mxy) then mxy := Level.Room[i].YPos;
	end;
	oOffsetX := 0;
	oOffsetY := mxy - mny + 1;
end;





procedure TRoomDuplicator.ApplySettings(iDstRoom, iSrcRoom: TKSRoom; iSettings: TRoomDuplicatorSettings);
var
	shift: char;
	RoomX, RoomY, X, Y: integer;
	HasRoomX, HasRoomY, HasX, HasY, HasAbsolute: boolean;
begin
	// Search for shifts and modify them:
	for shift := 'a' to 'c' do
	begin
		if not(iSrcRoom.ParseShift(RoomX, RoomY, X, Y, HasRoomX, HasRoomY, HasX, HasY, HasAbsolute, shift)) then
		begin
			continue;
		end;
		if not(HasRoomX) then
		begin
			RoomX := iSrcRoom.XPos;
		end;
		if not(HasRoomY) then
		begin
			RoomY :=iSrcRoom.YPos;
		end;

		// There is a shift, we have fully qualified it; now check it against the settings:
		if not(iSettings.ShouldModifyShift(HasAbsolute, not(IsRoomInSrc(RoomX, RoomY)))) then
		begin
			continue;
		end;

		// Modify the shift:
		iDstRoom.ModifyShiftDest(shift, RoomX + iDstRoom.XPos - iSrcRoom.XPos, RoomY + iDstRoom.YPos - iSrcRoom.YPos);
	end;		// for shift

	// Modify warp, if present:
	if (iDstRoom.DoesContainObject(0, KSOBJ_WARP)) then
	begin
		ApplySettingsWarps(iSrcRoom, iDstRoom, iSettings);
	end;
end;





procedure TRoomDuplicator.ApplySettingsWarps(iSrcRoom, iDstRoom: TKSRoom; iSettings: TRoomDuplicatorSettings);
begin
	iSrcRoom.UpdateFromData();		// Force re-read of warp settings

	// Modify individual warps:
	if (iSettings.ShouldModifyWarp(IsRoomInSrc(iSrcRoom.RoomLeft))) then
	begin
		iDstRoom.WarpXL := iSrcRoom.WarpXL + iSrcRoom.XPos - iDstRoom.XPos;
		iDstRoom.WarpYL := iSrcRoom.WarpYL + iSrcRoom.YPos - iDstRoom.YPos;
		iDstRoom.HasWarpL := iSrcRoom.HasWarpL;
	end;
	if (iSettings.ShouldModifyWarp(IsRoomInSrc(iSrcRoom.RoomRight))) then
	begin
		iDstRoom.WarpXR := iSrcRoom.WarpXR + iSrcRoom.XPos - iDstRoom.XPos;
		iDstRoom.WarpYR := iSrcRoom.WarpYR + iSrcRoom.YPos - iDstRoom.YPos;
		iDstRoom.HasWarpR := iSrcRoom.HasWarpR;
	end;
	if (iSettings.ShouldModifyWarp(IsRoomInSrc(iSrcRoom.RoomUp))) then
	begin
		iDstRoom.WarpXU := iSrcRoom.WarpXU + iSrcRoom.XPos - iDstRoom.XPos;
		iDstRoom.WarpYU := iSrcRoom.WarpYU + iSrcRoom.YPos - iDstRoom.YPos;
		iDstRoom.HasWarpU := iSrcRoom.HasWarpU;
	end;
	if (iSettings.ShouldModifyWarp(IsRoomInSrc(iSrcRoom.RoomDown))) then
	begin
		iDstRoom.WarpXD := iSrcRoom.WarpXD + iSrcRoom.XPos - iDstRoom.XPos;
		iDstRoom.WarpYD := iSrcRoom.WarpYD + iSrcRoom.YPos - iDstRoom.YPos;
		iDstRoom.HasWarpD := iSrcRoom.HasWarpD;
	end;

	// Set values back into EventParams:
	iDstRoom.SetWarpsToParams();
end;





function TRoomDuplicator.IsRoomInSrc(iRoomX, iRoomY: integer): boolean;
var
	i: integer;
begin
	if not(Self.SelectionOnly) then
	begin
		// All rooms are being copied:
		Result := true;
		Exit;
	end;

	// Search for room in selection:
	for i := 0 to Selection.Count - 1 do
	begin
		if ((TKSRoom(Selection[i]).XPos = iRoomX) and (TKSRoom(Selection[i]).YPos = iRoomY)) then
		begin
			Result := true;
			Exit;
		end;
	end;
	Result := false;
end;





function TRoomDuplicator.IsRoomInSrc(iRoom: TKSRoom): boolean;
begin
	if not(Assigned(iRoom)) then
	begin
		Result := false;
		Exit;
	end;
	Result := IsRoomInSrc(iRoom.XPos, iRoom.YPos);
end;





end.
