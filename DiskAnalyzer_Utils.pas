unit DiskAnalyzer_Utils;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.ShlObj,
  Vcl.ImgList,
  Vcl.Graphics;

type
  TSizeFormat = (sfBytes, sfKB, sfMB, sfGB, sfTB, sfAuto);

  TDiskUtils = class
  public
    class function FormatFileSize(ASize: Int64; AFormat: TSizeFormat = sfAuto): string;
    class function GetSizeInMB(ASize: Int64): Double;
    class function GetSizeInGB(ASize: Int64): Double;
    class function GetPercentage(APart, ATotal: Int64): Double;
    class function GetDriveCapacity(const APath: string): Int64;
    class procedure LoadSystemIcons(AImageList: TCustomImageList);
  end;

implementation

class function TDiskUtils.FormatFileSize(ASize: Int64; AFormat: TSizeFormat = sfAuto): string;
const
  KB = 1024;
  MB = 1024 * 1024;
  GB = 1024 * 1024 * 1024;
  TB = Int64(1024) * 1024 * 1024 * 1024;
var
  DBSize: Double;
begin
  case AFormat of
    sfBytes:
      Result := Format('%d B', [ASize]);
    sfKB:
      Result := Format('%.2f KB', [ASize / KB]);
    sfMB:
      Result := Format('%.2f MB', [ASize / MB]);
    sfGB:
      Result := Format('%.2f GB', [ASize / GB]);
    sfTB:
      Result := Format('%.2f TB', [ASize / TB]);
    sfAuto:
    begin
      if ASize < KB then
        Result := Format('%d B', [ASize])
      else if ASize < MB then
        Result := Format('%.2f KB', [ASize / KB])
      else if ASize < GB then
        Result := Format('%.2f MB', [ASize / MB])
      else if ASize < TB then
        Result := Format('%.2f GB', [ASize / GB])
      else
        Result := Format('%.2f TB', [ASize / TB]);
    end;
  end;
end;

class function TDiskUtils.GetSizeInMB(ASize: Int64): Double;
begin
  Result := ASize / (1024 * 1024);
end;

class function TDiskUtils.GetSizeInGB(ASize: Int64): Double;
begin
  Result := ASize / (1024 * 1024 * 1024);
end;

class function TDiskUtils.GetPercentage(APart, ATotal: Int64): Double;
begin
  if ATotal = 0 then
    Result := 0
  else
    Result := (APart / ATotal) * 100;
end;

class function TDiskUtils.GetDriveCapacity(const APath: string): Int64;
var
  RootPath: string;
  FreeAvailable, TotalBytes, TotalFree: Int64;
begin
  Result := 0;

  if APath = '' then
    Exit;

  RootPath := IncludeTrailingPathDelimiter(ExtractFileDrive(ExpandFileName(APath)));

  if RootPath = '' then
    Exit;

  if GetDiskFreeSpaceEx(PChar(RootPath), FreeAvailable, TotalBytes, @TotalFree) then
    Result := TotalBytes;
end;

class procedure TDiskUtils.LoadSystemIcons(AImageList: TCustomImageList);
const
  IconIds: array[0..4] of TSIID = (
    SIID_FOLDER,
    SIID_FOLDEROPEN,
    SIID_MEDIA_PLAY,
    SIID_MEDIA_STOP,
    SIID_DELETE
  );
var
  StockInfo: TSHStockIconInfo;
  IconHandle: HICON;
  Icon: TIcon;
  I: Integer;
  CreatedFromStock: Boolean;
begin
  if AImageList = nil then
    Exit;

  AImageList.BeginUpdate;
  try
    AImageList.Clear;
    AImageList.ColorDepth := cd32Bit;
    AImageList.Masked := True;
    AImageList.DrawingStyle := dsTransparent;
    AImageList.Width := GetSystemMetrics(SM_CXSMICON);
    AImageList.Height := GetSystemMetrics(SM_CYSMICON);

    for I := Low(IconIds) to High(IconIds) do
    begin
      ZeroMemory(@StockInfo, SizeOf(StockInfo));
      StockInfo.cbSize := SizeOf(StockInfo);
      IconHandle := 0;
      CreatedFromStock := False;

      if Succeeded(SHGetStockIconInfo(IconIds[I], SHGSI_ICON or SHGSI_SMALLICON, StockInfo)) then
      begin
        IconHandle := StockInfo.hIcon;
        CreatedFromStock := IconHandle <> 0;
      end;

      if IconHandle = 0 then
        IconHandle := LoadIcon(0, IDI_APPLICATION);

      if IconHandle <> 0 then
      begin
        Icon := TIcon.Create;
        try
          Icon.Handle := CopyIcon(IconHandle);
          AImageList.AddIcon(Icon);
        finally
          Icon.Free;
        end;

        if CreatedFromStock then
          DestroyIcon(IconHandle);
      end;
    end;
  finally
    AImageList.EndUpdate;
  end;
end;

end.
