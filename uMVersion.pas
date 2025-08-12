
unit uMVersion;

interface

uses
	Windows;





function ReadVersionInfo(sProgram: string; var Major, Minor, Release, Build : Word; var IsDebug: boolean): Boolean;		// true if successful
function GetModuleVersion(iModule: HModule; iDefault: string): string;
function ParseVersionString(iVersion: string; out Major, Minor, Release, Build: Word): boolean;		// true if successful



















implementation

uses
	SysUtils;





function ReadVersionInfo(sProgram: string; var Major, Minor, Release, Build : Word; var IsDebug: boolean): Boolean;
var
	Info: PVSFixedFileInfo;
{$ifdef VER120} {Delphi 4 definition for this differs from D2 & D3}
	InfoSize: Cardinal;
{$else}
	InfoSize: UINT;
{$endif}
	nHwnd: DWORD;
	BufferSize: DWORD;
	Buffer: Pointer;
begin
	BufferSize := GetFileVersionInfoSize(pchar(sProgram),nHWnd); {Get buffer size}
	Result := True;
	if BufferSize <> 0 then
	begin 												{if zero, there is no version info}
		GetMem( Buffer, BufferSize); {allocate buffer memory}
		try
			if GetFileVersionInfo(PChar(sProgram),nHWnd,BufferSize,Buffer) then
			begin
				{got version info}
				if VerQueryValue(Buffer, '\', Pointer(Info), InfoSize) then
				begin
					{got root block version information}
					Major := HiWord(Info^.dwFileVersionMS); {extract major version}
					Minor := LoWord(Info^.dwFileVersionMS); {extract minor version}
					Release := HiWord(Info^.dwFileVersionLS); {extract release version}
					Build := LoWord(Info^.dwFileVersionLS); {extract build version}
					IsDebug := ((Info.dwFileFlags and Info.dwFileFlagsMask and VS_FF_DEBUG) <> 0);
				end
				else
				begin
					Result := False; {no root block version info}
				end;
			end
			else
			begin
				Result := False; {couldn't extract version info}
			end;
		finally
			FreeMem(Buffer, BufferSize); {release buffer memory}
		end;
	end
	else
	begin
		Result := False; {no version info at all in the file}
	end;
end;





function GetModuleVersion(iModule: HModule; iDefault: string): string;
var
	fn: array[0..MAX_PATH] of Char;
	maj, min, rel, bui: word;
	isd: boolean;
begin
	GetModuleFileName(iModule, fn, MAX_PATH);
	if ReadVersionInfo(string(fn), maj, min, rel, bui, isd) then
	begin
		Result := IntToStr(maj) + '.' + IntToStr(min) + '.' + IntToStr(rel) + '.' + IntToStr(bui);
		if isd then Result := Result + ' (debug)';
	end
	else
		Result := iDefault;
end;





function ParseVersionString(iVersion: string; out Major, Minor, Release, Build: Word): boolean;		// true if successful
var
	code, code2: integer;
begin
	Result := true;
	Major := 0;
	Minor := 0;
	Release := 0;
	Build := 0;
	val(iVersion, Major, code);
	if (code = 0) then
	begin
		Exit;
	end;
	val(copy(iVersion, 1, code - 1), Major, code2);
	if (code2 > 0) then
	begin
		Result := false;
		Exit;
	end;
	iVersion := copy(iVersion, code + 1, Length(iVersion));

	val(iVersion, Minor, code);
	if (code = 0) then
	begin
		Exit;
	end;
	val(copy(iVersion, 1, code - 1), Minor, code2);
	if (code2 > 0) then
	begin
		Result := false;
		Exit;
	end;
	iVersion := copy(iVersion, code + 1, Length(iVersion));

	val(iVersion, Release, code);
	if (code = 0) then
	begin
		Exit;
	end;
	val(copy(iVersion, 1, code - 1), Release, code2);
	if (code2 > 0) then
	begin
		Result := false;
		Exit;
	end;
	iVersion := copy(iVersion, code + 1, Length(iVersion));

	val(iVersion, Build, code);
	if (code = 0) then
	begin
		Exit;
	end;
	val(copy(iVersion, 1, code - 1), Build, code2);
	if (code2 > 0) then
	begin
		Result := false;
	end;
end;





end.

