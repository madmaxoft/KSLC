
unit ZLib1Dll;

interface

uses
	Windows,
	Classes;





type
	gzFile = pointer;





function gzCompress   (var oDest; var oDestLen: cardinal; const iSource; iSourceLen: cardinal): integer; cdecl; external 'zlib1.dll' name 'compress';
function gzCompress2  (var oDest; var oDestLen: cardinal; const iSource; iSourceLen: cardinal; iLevel: integer): integer; cdecl; external 'zlib1.dll' name 'compress2';
function gzUncompress (var oDest; var oDestLen: cardinal; const iSource; iSourceLen: cardinal): integer; cdecl; external 'zlib1.dll' name 'uncompress';
function gzOpen     (const Path: PChar; const Mode: PChar): gzfile; cdecl; external 'zlib1.dll' name 'gzopen';
function gzSetparams(iFile: gzfile; iLevel, iStrategy: integer): integer; cdecl; external 'zlib1.dll' name 'gzsetparams';
function gzRead     (iFile: gzfile; var oDest; iLen: cardinal): integer; cdecl; external 'zlib1.dll' name 'gzread';
function gzWrite    (iFile: gzfile; const iBuf; iLen: cardinal): integer; cdecl; external 'zlib1.dll' name 'gzwrite';
function gzPutc     (iFile: gzfile; c: integer): integer; cdecl; external 'zlib1.dll' name 'gzputc';
function gzGetc     (iFile: gzfile): integer; cdecl; external 'zlib1.dll' name 'gzgetc';
function gzFlush    (iFile: gzfile; iFlush: integer): integer; cdecl; external 'zlib1.dll' name 'gzflush';
function gzEof      (iFile: gzfile): integer; cdecl; external 'zlib1.dll' name 'gzeof';
function gzClose    (iFile: gzfile): integer; cdecl; external 'zlib1.dll' name 'gzclose';
function gzWriteString(iFile: gzFile; iString: string): integer;





implementation





function gzWriteString(iFile: gzFile; iString: string): integer;
begin
	Result := gzWrite(iFile, iString[1], Length(iString));
end;





end.


