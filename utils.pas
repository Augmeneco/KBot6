unit Utils;

interface

  uses
    fpjson, jsonparser;

  type
    TLogType = (logNormal, logGood, logError, logWarning);

  var
    config: TJSONObject;

  procedure logWrite(str: UnicodeString; logType: TLogType=TLogType.logNormal);


implementation
  uses
    sysutils;

  var
    configFile: TextFile;
    configText, buffer: String;

  procedure logWrite(str: UnicodeString; logType: TLogType=TLogType.logNormal);
  var
    logTime: TDateTime;
  begin
    logTime := now();
    writeln(formatDateTime('[dd/mm/yy hh:nn:ss"."zzz]', logTime), ' ', str);
  end;

begin
  if not fileExists('./bot.cfg') then
  begin
    writeLn('ERROR: Config "bot.cfg" not exist!');
    halt(1);
  end;

  assignFile(configFile, './bot.cfg');
  try
    reset(configFile);
    while not eof(configFile) do
    begin
      readln(configFile, buffer);
      configText += buffer;
    end;
    closeFile(configFile);
  except
    on E: EInOutError do
      writeln('File handling error occurred. Details: ', E.message);
  end;
  config := TJSONObject(getJSON(configText));
end.

