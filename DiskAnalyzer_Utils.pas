unit DiskAnalyzer_Utils;

interface

uses
  System.SysUtils;

type
  TSizeFormat = (sfBytes, sfKB, sfMB, sfGB, sfTB, sfAuto);

  TDiskUtils = class
  public
    class function FormatFileSize(ASize: Int64; AFormat: TSizeFormat = sfAuto): string;
    class function GetSizeInMB(ASize: Int64): Double;
    class function GetSizeInGB(ASize: Int64): Double;
    class function GetPercentage(APart, ATotal: Int64): Double;
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

end.
