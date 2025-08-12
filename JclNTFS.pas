{******************************************************************************}
{                                                                              }
{ Project JEDI Code Library (JCL)                                              }
{                                                                              }
{ The contents of this file are subject to the Mozilla Public License Version  }
{ 1.1 (the "License"); you may not use this file except in compliance with the }
{ License. You may obtain a copy of the License at http://www.mozilla.org/MPL/ }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ The Original Code is JclNTFS.pas.                                            }
{                                                                              }
{ The Initial Developer of the Original Code is documented in the accompanying }
{ help file JCL.chm. Portions created by these individuals are Copyright (C)   }
{ 2000 of these individuals.                                                   }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Contains routines to perform filesystem related tasks available only with    }
{ NTFS. These are mostly relatively straightforward wrappers for various IOCTs }
{ related to compression, sparse files, reparse points, volume mount points    }
{ and so forth. Note that some functions require NTFS 5 or higher!             }
{                                                                              }
{ Unit Owner: Marcel van Brakel                                                }
{ Last modified: July 05, 2001                                                 }
{                                                                              }
{******************************************************************************}

unit JclNTFS;

{$I JCL.INC}

{$WEAKPACKAGEUNIT ON}

interface

uses
  Windows,
{$IFDEF FPC}
  FileUtil,
{$ENDIF}
  JclBase,
  JclWin32;

//------------------------------------------------------------------------------
// NTFS - Compression
//------------------------------------------------------------------------------

function NtfsGetCompression(const FileName: string; var State: Short): Boolean;
function NtfsSetCompression(const FileName: string; const State: Short): Boolean;
function NtfsSetCompressionRecursively(const Directory: string; const State: Short): Boolean;

//------------------------------------------------------------------------------
// NTFS - Sparse Files
//------------------------------------------------------------------------------

type
  TNtfsAllocRanges = record
    Entries: Integer;
    Data: PFileAllocatedRangeBuffer;
    MoreData: Boolean;
  end;

function NtfsSetSparse(const FileName: string): Boolean;
function NtfsZeroDataByHandle(const Handle: THandle; const First, Last: Int64): Boolean;
function NtfsZeroDataByName(const FileName: string; const First, Last: Int64): Boolean;
function NtfsQueryAllocRanges(const FileName: string; Offset, Count: Int64; var Ranges: TNtfsAllocRanges): Boolean;
function NtfsGetAllocRangeEntry(const Ranges: TNtfsAllocRanges; Index: Integer): TFileAllocatedRangeBuffer;
function NtfsSparseStreamsSupported(const Volume: string): Boolean;
function NtfsGetSparse(const FileName: string): Boolean;

//------------------------------------------------------------------------------
// NTFS - Reparse Points
//------------------------------------------------------------------------------

function NtfsDeleteReparsePoint(const FileName: string; ReparseTag: DWORD): Boolean;
function NtfsSetReparsePoint(const FileName: string; var ReparseData; Size: Longword): Boolean;
function NtfsGetReparsePoint(const FileName: string; var ReparseData: TReparseGuidDataBuffer): Boolean;
function NtfsGetReparseTag(const Path: string; var Tag: DWORD): Boolean;
function NtfsReparsePointsSupported(const Volume: string): Boolean;
function NtfsFileHasReparsePoint(const Path: string): Boolean;

//------------------------------------------------------------------------------
// NTFS - Volume Mount Points
//------------------------------------------------------------------------------

function NtfsIsFolderMountPoint(const Path: string): Boolean;
function NtfsMountDeviceAsDrive(const Device: string; Drive: Char): Boolean;
function NtfsMountVolume(const Volume: Char; const MountPoint: string): Boolean;

//------------------------------------------------------------------------------
// NTFS - Change Journal
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// NTFS - Opportunistic Locks
//------------------------------------------------------------------------------

type
  TOpLock = (olExclusive, olReadOnly, olBatch, olFilter);

function NtfsOpLockAckClosePending(Handle: THandle; Overlapped: TOverlapped): Boolean;
function NtfsOpLockBreakAckNo2(Handle: THandle; Overlapped: TOverlapped): Boolean;
function NtfsOpLockBreakAcknowledge(Handle: THandle; Overlapped: TOverlapped): Boolean;
function NtfsOpLockBreakNotify(Handle: THandle; Overlapped: TOverlapped): Boolean;
function NtfsRequestOpLock(Handle: THandle; Kind: TOpLock; Overlapped: TOverlapped): Boolean;

//------------------------------------------------------------------------------
// Junction Points
//------------------------------------------------------------------------------

function NtfsCreateJunctionPoint(const Source, Destination: string): Boolean;
function NtfsDeleteJunctionPoint(const Source: string): Boolean;
function NtfsGetJunctionPointDestination(const Source: string; var Destination: string): Boolean;

//------------------------------------------------------------------------------
// Streams
//------------------------------------------------------------------------------

type
  TStreamId = (siInvalid, siStandard, siExtendedAttribute, siSecurity, siAlternate,
    siHardLink, siProperty, siObjectIdentifier, siReparsePoints, siSparseFile);
  TStreamIds = set of TStreamId;

  TInternalFindStreamData = record
    FileHandle: THandle;
    Context: Pointer;
    StreamIds: TStreamIds;
  end;

  TFindStreamData = record
    Internal: TInternalFindStreamData;
    Attributes: DWORD;
    StreamID: TStreamId;
    Name: WideString;
    Size: Int64;
  end;

function NtfsFindFirstStream(const FileName: string; StreamIds: TStreamIds;
  var Data: TFindStreamData): Boolean;
function NtfsFindNextStream(var Data: TFindStreamData): Boolean;
function NtfsFindStreamClose(var Data: TFindStreamData): Boolean;

type
  EJclNtfsError = class (EJclWin32Error);

implementation

uses
  SysUtils,
  JclFileUtils, JclResources;

//==============================================================================
// NTFS - Compression
//==============================================================================

function NtfsGetCompression(const FileName: string; var State: Short): Boolean;
var
  Handle: THandle;
  BytesReturned: DWORD;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Result := DeviceIoControl(Handle, FSCTL_GET_COMPRESSION, nil, 0, @State,
      SizeOf(Short), BytesReturned, nil);
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsSetCompression(const FileName: string; const State: Short): Boolean;
const
  FileFlag: array[Boolean] of DWORD = (0, FILE_FLAG_BACKUP_SEMANTICS);
var
  Handle: THandle;
  BytesReturned: DWORD;
  Buffer: Short;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ, nil, OPEN_EXISTING, FileFlag[IsDirectory(FileName)], 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Buffer := State;
    Result := DeviceIoControl(Handle, FSCTL_SET_COMPRESSION, @Buffer,
      SizeOf(Short), nil, 0, BytesReturned, nil);
  finally
    CloseHandle(Handle);
  end
end;

//------------------------------------------------------------------------------

function NtfsSetCompressionRecursively(const Directory: string; const State: Short): Boolean;
var
  SearchRec: TSearchRec;
  R: Integer;
  FileName, Dir: string;
begin
  Result := NtfsSetCompression(Directory, State);
  if not Result then
    Exit;
  Dir := PathAddSeparator(Directory);
{$IFnDEF FPC}
  if FindFirst(Dir + '*.*', faAnyFile, SearchRec) = 0 then
{$ELSE}
  if FindFirstUTF8(Dir + '*.*', faAnyFile, SearchRec) = 0 then
{$ENDIF}
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        FileName := Dir + SearchRec.Name;
        Result := NtfsSetCompression(FileName, State);
        if Result then
          if (SearchRec.Attr and faDirectory) <> 0 then
            Result := NtfsSetCompressionRecursively(FileName, State);
        if not Result then
          Exit;
      end;
{$IFnDEF FPC}
      R := FindNext(SearchRec);
{$ELSE}
      R := FindNextUTF8(SearchRec);
{$ENDIF}
    until R <> 0;
    Result := R = ERROR_NO_MORE_FILES;
  finally
    SysUtils.FindClose(SearchRec);
  end;
end;

//==============================================================================
// NTFS - Sparse Files
//==============================================================================

function NtfsSetSparse(const FileName: string): Boolean;
var
  Handle: THandle;
  BytesReturned: DWORD;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Result := DeviceIoControl(Handle, FSCTL_SET_SPARSE, nil, 0, nil, 0, BytesReturned, nil);
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsZeroDataByHandle(const Handle: THandle; const First, Last: Int64): Boolean;
var
  BytesReturned: DWORD;
  ZeroDataInfo: TFileZeroDataInformation;
  Info: TByHandleFileInformation;
begin
  Result := False;
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    // Continue only if the file is a sparse file, this avoids the overhead
    // associated with an IOCTL when the file isn't even a sparse file.
    GetFileInformationByHandle(Handle, Info);
    Result := (Info.dwFileAttributes and FILE_ATTRIBUTE_SPARSE_FILE) <> 0;
    if Result then
    begin
      ZeroDataInfo.FileOffset := First;
      ZeroDataInfo.BeyondFinalZero := Last;
      Result := DeviceIoControl(Handle, FSCTL_SET_ZERO_DATA, @ZeroDataInfo,
        SizeOf(ZeroDataInfo), nil, 0, BytesReturned, nil);
    end;
  end;
end;

//------------------------------------------------------------------------------

function NtfsZeroDataByName(const FileName: string; const First, Last: Int64): Boolean;
var
  Handle: THandle;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Result := NtfsZeroDataByHandle(Handle, First, Last);
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsGetAllocRangeEntry(const Ranges: TNtfsAllocRanges;
  Index: Integer): TFileAllocatedRangeBuffer;
var
  Offset: Longint;
begin
  Assert((Index >= 0) and (Index < Ranges.Entries));
  Offset := Longint(Ranges.Data) + Index * SizeOf(TFileAllocatedRangeBuffer);
  Result := PFileAllocatedRangeBuffer(Offset)^;
end;

//------------------------------------------------------------------------------

function __QueryAllocRanges(const Handle: THandle; const Offset, Count: Int64;
  var Ranges: PFileAllocatedRangeBuffer; var MoreData: Boolean; var Size: Cardinal): Boolean;
var
  BytesReturned: DWORD;
  SearchRange: TFileAllocatedRangeBuffer;
  BufferSize: Cardinal;
begin
  SearchRange.FileOffset := Offset;
  SearchRange.Length := Count;
  BufferSize := 4 * 64 * SizeOf(TFileAllocatedRangeBuffer);
  Ranges := AllocMem(BufferSize);
  Result := DeviceIoControl(Handle, FSCTL_QUERY_ALLOCATED_RANGES, @SearchRange,
    SizeOf(SearchRange), Ranges, BufferSize, BytesReturned, nil);
  MoreData := GetLastError = ERROR_MORE_DATA;
  if MoreData then
    Result := True;
  Size := BytesReturned;
  if BytesReturned = 0 then
  begin
    FreeMem(Ranges);
    Ranges := nil;
  end;
end;

function NtfsQueryAllocRanges(const FileName: string; Offset, Count: Int64;
  var Ranges: TNtfsAllocRanges): Boolean;
var
  Handle: THandle;
  CurrRanges: PFileAllocatedRangeBuffer;
  R, MoreData: Boolean;
  Size: Cardinal;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    R := __QueryAllocRanges(Handle, Offset, Count, CurrRanges, MoreData, Size);
    Ranges.MoreData := MoreData;
    Result := R;
    if R then
    begin
      Ranges.Entries := Size div SizeOf(TFileAllocatedRangeBuffer);
      Ranges.Data := CurrRanges;
    end
    else
    begin
      Ranges.Entries := 0;
      Ranges.Data := nil;
    end;
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsSparseStreamsSupported(const Volume: string): Boolean;
var
  MCL, Flags: Cardinal;
begin
  Result := GetVolumeInformation(PChar(Volume), nil, 0, nil, MCL, Flags, nil, 0);
  if Result then
    Result := (Flags and FILE_SUPPORTS_SPARSE_FILES) <> 0;
end;

//------------------------------------------------------------------------------

function NtfsGetSparse(const FileName: string): Boolean;
var
  Handle: THandle;
  Info: TByHandleFileInformation;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, 0, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    GetFileInformationByHandle(Handle, Info);
    Result := (Info.dwFileAttributes and FILE_ATTRIBUTE_SPARSE_FILE) <> 0;
  finally
    CloseHandle(Handle);
  end;
end;

//==============================================================================
// NTFS - Reparse Points
//==============================================================================

function NtfsGetReparseTag(const Path: string; var Tag: DWORD): Boolean;
var
  SearchRec: TSearchRec;
begin
  Result := NtfsFileHasReparsePoint(Path);
  if Result then
  begin
{$IFnDEF FPC}
    Result := FindFirst(Path, faAnyFile, SearchRec) = 0;
{$ELSE}
    Result := FindFirstUTF8(Path, faAnyFile, SearchRec) = 0;
{$ENDIF}
    if Result then
    begin
      // Check if file has a reparse point
      Result := ((SearchRec.Attr and FILE_ATTRIBUTE_REPARSE_POINT) <> 0);
      // If so the dwReserved0 field contains the reparse tag
      if Result then
        Tag := SearchRec.FindData.dwReserved0;
{$IFnDEF FPC}
      FindClose(SearchRec);
{$ELSE}
      FindCloseUTF8(SearchRec);
{$ENDIF}
    end;
  end;
end;

//------------------------------------------------------------------------------

function NtfsReparsePointsSupported(const Volume: string): Boolean;
var
  MCL, Flags: Cardinal;
begin
  Result := GetVolumeInformation(PChar(Volume), nil, 0, nil, MCL, Flags, nil, 0);
  if Result then
    Result := (Flags and FILE_SUPPORTS_REPARSE_POINTS) <> 0;
end;

//------------------------------------------------------------------------------

function NtfsFileHasReparsePoint(const Path: string): Boolean;
var
  Attr: DWORD;
begin
  Result := False;
  Attr := GetFileAttributes(PChar(Path));
  if Attr <> DWORD(-1) then
    Result := (Attr and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
end;

//------------------------------------------------------------------------------

function NtfsDeleteReparsePoint(const FileName: string; ReparseTag: DWORD): Boolean;
var
  Handle: THandle;
  BytesReturned: DWORD;
  ReparseData: TReparseGuidDataBuffer;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    FillChar(ReparseData, SizeOf(ReparseData), #0);
    ReparseData.ReparseTag := ReparseTag;
    Result := DeviceIoControl(Handle, FSCTL_DELETE_REPARSE_POINT, @ReparseData,
      REPARSE_GUID_DATA_BUFFER_HEADER_SIZE, nil, 0, BytesReturned, nil);
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsSetReparsePoint(const FileName: string; var ReparseData; Size: Longword): Boolean;
var
  Handle: THandle;
  BytesReturned: DWORD;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Result := DeviceIoControl(Handle, FSCTL_SET_REPARSE_POINT, @ReparseData,
      Size, nil, 0, BytesReturned, nil);
  finally
    CloseHandle(Handle);
  end;
end;

//------------------------------------------------------------------------------

function NtfsGetReparsePoint(const FileName: string; var ReparseData: TReparseGuidDataBuffer): Boolean;
var
  Handle: THandle;
  BytesReturned: DWORD;
  LastError: DWORD;
begin
  Result := False;
  Handle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
  LastError := GetLastError;
  if Handle <> INVALID_HANDLE_VALUE then
  try
    Result := DeviceIoControl(Handle, FSCTL_GET_REPARSE_POINT, nil, 0, @ReparseData,
      ReparseData.ReparseDataLength + SizeOf(ReparseData), BytesReturned, nil);
    if not Result then
    begin
      ReparseData.ReparseDataLength := BytesReturned;
      LastError := GetLastError;
    end;
  finally
    CloseHandle(Handle);
    SetLastError(LastError);
  end;
end;

//==============================================================================
// NTFS - Volume Mount Points
//==============================================================================

function NtfsIsFolderMountPoint(const Path: string): Boolean;
var
  Tag: DWORD;
begin
  Result := NtfsGetReparseTag(Path, Tag);
  if Result then
    Result := (Tag = IO_REPARSE_TAG_MOUNT_POINT);
end;

//------------------------------------------------------------------------------

function NtfsMountDeviceAsDrive(const Device: string; Drive: Char): Boolean;
const
  DDD_FLAGS = DDD_RAW_TARGET_PATH or DDD_REMOVE_DEFINITION or DDD_EXACT_MATCH_ON_REMOVE;
var
  DriveStr: string;
  VolumeName: string;
begin
  // To create a mount point we must obtain a unique volume name first. To obtain
  // a unique volume name the drive must exist. Therefore we must temporarily
  // create a symbolic link for the drive using DefineDosDevice.
  DriveStr := Drive + ':';
  Result := DefineDosDevice(DDD_RAW_TARGET_PATH, PChar(DriveStr), PChar(Device));
  if Result then
  begin
    SetLength(VolumeName, 1024);
    Result := GetVolumeNameForVolumeMountPoint(PChar(DriveStr + '\'),
      PChar(VolumeName), 1024);
    // Attempt to delete the symbolic link, if it fails then don't attempt to
    // set the mountpoint either but raise an exception instead, there's something
    // seriously wrong so let's try to control the damage done already :)
    if not DefineDosDevice(DDD_FLAGS, PChar(DriveStr), PChar(Device)) then
      raise EJclNtfsError.CreateResRec(@RsNtfsUnableToDeleteSymbolicLink);
    if Result then
      Result := SetVolumeMountPoint(PChar(DriveStr + '\'), PChar(VolumeName));
  end;
end;

//------------------------------------------------------------------------------

function NtfsMountVolume(const Volume: Char; const MountPoint: string): Boolean;
var
  VolumeName: string;
  VolumeStr: string;
begin
  SetLength(VolumeName, 1024);
  VolumeStr := Volume + ':\';
  Result := GetVolumeNameForVolumeMountPoint(PChar(VolumeStr), PChar(VolumeName), 1024);
  if Result then
  begin
{$IFnDEF FPC}
    if not DirectoryExists(MountPoint) then
      ForceDirectories(MountPoint);
{$ELSE}
    if not DirectoryExistsUTF8(MountPoint) then
      ForceDirectoriesUTF8(MountPoint);
{$ENDIF}
    Result := SetVolumeMountPoint(PChar(MountPoint), PChar(VolumeName));
  end;
end;

//==============================================================================
// NTFS - Change Journal
//==============================================================================

//==============================================================================
// NTFS - Opportunistic Locks
//==============================================================================

function NtfsOpLockAckClosePending(Handle: THandle; Overlapped: TOverlapped): Boolean;
var
  BytesReturned: Cardinal;
begin
  Result := DeviceIoControl(Handle, FSCTL_OPBATCH_ACK_CLOSE_PENDING, nil, 0, nil,
    0, BytesReturned, @Overlapped);
end;

//------------------------------------------------------------------------------

function NtfsOpLockBreakAckNo2(Handle: THandle; Overlapped: TOverlapped): Boolean;
var
  BytesReturned: Cardinal;
begin
  Result := DeviceIoControl(Handle, FSCTL_OPLOCK_BREAK_ACK_NO_2, nil, 0, nil, 0,
    BytesReturned, @Overlapped);
end;

//------------------------------------------------------------------------------

function NtfsOpLockBreakAcknowledge(Handle: THandle; Overlapped: TOverlapped): Boolean;
var
  BytesReturned: Cardinal;
begin
  Result := DeviceIoControl(Handle, FSCTL_OPLOCK_BREAK_ACKNOWLEDGE, nil, 0, nil,
    0, BytesReturned, @Overlapped);
  Result := Result or (GetLastError = ERROR_IO_PENDING);
end;

//------------------------------------------------------------------------------

function NtfsOpLockBreakNotify(Handle: THandle; Overlapped: TOverlapped): Boolean;
var
  BytesReturned: Cardinal;
begin
  Result := DeviceIoControl(Handle, FSCTL_OPLOCK_BREAK_NOTIFY, nil, 0, nil, 0,
    BytesReturned, @Overlapped);
end;

//------------------------------------------------------------------------------

function NtfsRequestOpLock(Handle: THandle; Kind: TOpLock; Overlapped: TOverlapped): Boolean;
const
  IoCodes: array [TOpLock] of Cardinal = (
    FSCTL_REQUEST_OPLOCK_LEVEL_1, FSCTL_REQUEST_OPLOCK_LEVEL_2,
    FSCTL_REQUEST_BATCH_OPLOCK, FSCTL_REQUEST_FILTER_OPLOCK);
var
  BytesReturned: Cardinal;
begin
  Result := DeviceIoControl(Handle, IoCodes[Kind], nil, 0, nil, 0, BytesReturned, @Overlapped);
  Result := Result or (GetLastError = ERROR_IO_PENDING);
end;

//==============================================================================
// Junction Points
//==============================================================================

function IsReparseTagValid(Tag: DWORD): Boolean;
begin
  Result := (Tag and (not IO_REPARSE_TAG_VALID_VALUES) = 0) and
    (Tag > IO_REPARSE_TAG_RESERVED_RANGE);
end;

//------------------------------------------------------------------------------

function NtfsCreateJunctionPoint(const Source, Destination: string): Boolean;
var
  Dest: array [0..1024] of Char; // Writable copy of Destination
  DestW: WideString;             // Unicode version of Dest
  FullDir: array [0..1024] of Char;
  FilePart: PChar;
  Buffer: array [0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE] of Char;
  ReparseData: TReparseDataBuffer absolute Buffer;
  NameLength: Longword;
begin
  Result := False;
  // For some reason the destination string must be prefixed with \??\ otherwise
  // the IOCTL will fail, ensure it's there.
  if Copy(Destination, 1, 2) = '\??' then
    StrPCopy(Dest, Destination)
  else
  begin
    // Make sure Destination is a directory or again, the IOCTL will fail.
    if (GetFullPathName(PChar(Destination), 1024, FullDir, FilePart) = 0) or
      (GetFileAttributes(FullDir) = DWORD(-1)) then
    begin
      SetLastError(ERROR_PATH_NOT_FOUND);
      Exit;
    end;
    StrPCopy(Dest, '\??\' + Destination);
  end;
  FillChar(ReparseData, SizeOf(ReparseData), #0);
  NameLength := StrLen(Dest) * SizeOf(WideChar);
  ReparseData.ReparseTag := IO_REPARSE_TAG_MOUNT_POINT;
  ReparseData.ReparseDataLength := NameLength + 12;
  ReparseData.SubstituteNameLength := NameLength;
  ReparseData.PrintNameOffset := NameLength + 2;
  // Not the most ellegant way to copy an AnsiString into an Unicode buffer but
  // let's avoid dependencies on JclUnicode.pas (adds significant resources).
  DestW := WideString(Dest);
  Move(DestW[1], ReparseData.PathBuffer, Length(DestW) * SizeOf(WideChar));
  Result := NtfsSetReparsePoint(Source, ReparseData,
    ReparseData.ReparseDataLength + REPARSE_DATA_BUFFER_HEADER_SIZE);
end;

//------------------------------------------------------------------------------

function NtfsDeleteJunctionPoint(const Source: string): Boolean;
begin
  Result := NtfsDeleteReparsePoint(Source, IO_REPARSE_TAG_MOUNT_POINT);
end;

//------------------------------------------------------------------------------

const
  CP_THREAD_ACP = 3;           // current thread's ANSI code page

function NtfsGetJunctionPointDestination(const Source: string; var Destination: string): Boolean;
var
  Handle: THandle;
  Buffer: array [0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE] of Char;
  ReparseData: TReparseDataBuffer absolute Buffer;
  BytesReturned: DWORD;
begin
  Result := False;
  if NtfsFileHasReparsePoint(Source) then
  begin
    Handle := CreateFile(PChar(Source), GENERIC_READ, 0, nil,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
    if Handle <> INVALID_HANDLE_VALUE then
    try
      if DeviceIoControl(Handle, FSCTL_GET_REPARSE_POINT, nil, 0, @ReparseData,
        MAXIMUM_REPARSE_DATA_BUFFER_SIZE, BytesReturned, nil) {and
        IsReparseTagValid(ReparseData.ReparseTag) then}
        then
      begin
        if BytesReturned >= ReparseData.SubstituteNameLength + SizeOf(WideChar) then
        begin
          SetLength(Destination, (ReparseData.SubstituteNameLength div SizeOf(WideChar)) + 1);
          WideCharToMultiByte(CP_THREAD_ACP, 0, ReparseData.PathBuffer,
            (ReparseData.SubstituteNameLength div SizeOf(WCHAR)) + 1,
            PChar(Destination), Length(Destination), nil, nil);
          Result := True;
        end;
      end;
    finally
      CloseHandle(Handle);
    end
  end;
end;

//==============================================================================
// Streams
//==============================================================================

// Delphi's declaration of BackupSeek is wrong (last parameter is missing var).

function BackupSeek(hFile: THandle; dwLowBytesToSeek, dwHighBytesToSeek: DWORD;
  var lpdwLowByteSeeked, lpdwHighByteSeeked: DWORD; var lpContext: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'BackupSeek';

// FindStream is an internal helper routine for NtfsFindFirstStream and
// NtfsFindNextStream. It uses the backup API to enumerate the streams in an
// NTFS file and returns when it either finds a stream that matches the filter
// specified in the Data parameter or hits EOF. Details are returned through
// the Data parameter and success/failure as the Boolean result value.

function FindStream(var Data: TFindStreamData): Boolean;
var
  Header: TWin32StreamId;
  BytesToRead, BytesRead: DWORD;
  BytesToSeek: TLargeInteger;
  Hi, Lo: DWORD;
  FoundStream: Boolean;
  StreamName: PWideChar;
begin
  Result := False;
  FoundStream := False;
  // We loop until we either found a stream or an error occurs.
  while not FoundStream do
  begin
    // Read stream header
    BytesToRead := DWORD(@Header.cStreamName[0]) - DWORD(@Header.dwStreamId);
    if not BackupRead(Data.Internal.FileHandle, (@Header), BytesToRead, BytesRead,
      False, True, Data.Internal.Context) then
    begin
      SetLastError(ERROR_READ_FAULT);
      Exit;
    end;
    if BytesRead = 0 then // EOF
    begin
      SetLastError(ERROR_NO_MORE_FILES);
      Exit;
    end;
    // If stream has a name then read it
    if Header.dwStreamNameSize > 0 then
    begin
      StreamName := HeapAlloc(GetProcessHeap, 0, Header.dwStreamNameSize + SizeOf(WCHAR));
      if StreamName = nil then
      begin
        SetLastError(ERROR_OUTOFMEMORY);
        Exit;
      end;
      if not BackupRead(Data.Internal.FileHandle, Pointer(StreamName),
        Header.dwStreamNameSize, BytesRead, False, True, Data.Internal.Context) then
      begin
        HeapFree(GetProcessHeap, 0, StreamName);
        SetLastError(ERROR_READ_FAULT);
        Exit;
      end;
      StreamName[Header.dwStreamNameSize div SizeOf(WCHAR)] := WideChar(#0);
    end
    else StreamName := nil;
    // Did we find any of the specified streams ([] means any stream)?
    if (Data.Internal.StreamIds = []) or
      (TStreamId(Header.dwStreamId) in Data.Internal.StreamIds) then
    begin
      FoundStream := True;
{$IFnDEF FPC}
      Data.Size := Header.Size;
{$ELSE}
      Data.Size := Header.Size.QuadPart;
{$ENDIF}
      Data.Name := StreamName;
      Data.Attributes := Header.dwStreamAttributes;
      Data.StreamId := TStreamId(Header.dwStreamId);
    end;
    // Release stream name memory if necessary
    if Header.dwStreamNameSize > 0 then
      HeapFree(GetProcessHeap, 0, StreamName);
    // Move past data part to beginning of next stream (or EOF)
{$IFnDEF FPC}
    BytesToSeek.QuadPart := Header.Size;
{$ELSE}
    BytesToSeek.QuadPart := Header.Size.QuadPart;
{$ENDIF}
    if not BackupSeek(Data.Internal.FileHandle, BytesToSeek.LowPart,
      BytesToSeek.HighPart, Lo, Hi, Data.Internal.Context) then
    begin
      SetLastError(ERROR_READ_FAULT);
      Exit;
    end;
  end;
  // Due to the usage of Exit, we only get here if everything succeeded
  Result := True;
end;

//------------------------------------------------------------------------------

function NtfsFindFirstStream(const FileName: string; StreamIds: TStreamIds;
  var Data: TFindStreamData): Boolean;
begin
  Result := False;
  // Open file for reading, note that the FILE_FLAG_BACKUP_SEMANTICS requires
  // the SE_BACKUP_NAME and SE_RESTORE_NAME privileges.
  Data.Internal.FileHandle := CreateFile(PChar(FileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS, 0);
  if Data.Internal.FileHandle <> INVALID_HANDLE_VALUE then
  begin
    // Initialize private context
    Data.Internal.StreamIds := StreamIds;
    Data.Internal.Context := nil;
    // Call upon the Borg worker to find the next (first) stream
    Result := FindStream(Data);
    if not Result then
    begin
      // Failure, cleanup relieving the caller of having to call FindStreamClose
      CloseHandle(Data.Internal.FileHandle);
      Data.Internal.FileHandle := INVALID_HANDLE_VALUE;
      Data.Internal.Context := nil;
      if GetLastError = ERROR_NO_MORE_FILES then
        SetLastError(ERROR_FILE_NOT_FOUND);
    end;
  end;
end;

//------------------------------------------------------------------------------

function NtfsFindNextStream(var Data: TFindStreamData): Boolean;
begin
  Result := False;
  if Data.Internal.FileHandle <> INVALID_HANDLE_VALUE then
    Result := FindStream(Data)
  else
    SetLastError(ERROR_INVALID_HANDLE);
end;

//------------------------------------------------------------------------------

function NtfsFindStreamClose(var Data: TFindStreamData): Boolean;
var
  BytesRead: DWORD;
begin
  if Data.Internal.FileHandle <> INVALID_HANDLE_VALUE then
  begin
    // Call BackupRead one last time to signal that we're done with it
    BackupRead(0, nil, 0, BytesRead, True, False, Data.Internal.Context);
    CloseHandle(Data.Internal.FileHandle);
    Data.Internal.FileHandle := INVALID_HANDLE_VALUE;
    Data.Internal.Context := nil;
    Result := True;
  end
  else
  begin
    SetLastError(ERROR_INVALID_HANDLE);
    Result := False;
  end;
end;

end.
