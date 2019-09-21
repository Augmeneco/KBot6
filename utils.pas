unit Utils;

interface

  uses
    fpjson, jsonparser;

  type
    TLogType = (logNormal, logGood, logError, logWarning);

  var
    config: TJSONObject;
    botStartTime: Int64;

  threadvar
    logThreadId: Integer;

  procedure logWrite(str: String; logType: TLogType=TLogType.logNormal);


implementation
  uses
    sysutils;

  var
    configFile: TextFile;
    configText, buffer: String;
    enableColors: Boolean = True;
    i: Integer;

  procedure logWrite(str: String; logType: TLogType=TLogType.logNormal);
  var
    logTime: TDateTime;
  begin
    logTime := now();
    //if enableColors then
    //  case logType of
    //    TLogType.logNormal:
    //      textColor(LightGray);
    //    TLogType.logGood:
    //      textColor(Green);
    //    TLogType.logError:
    //      textColor(Red);
    //    TLogType.logWarning:
    //      textColor(Yellow);
    //  end;
    writeln(format('[%s][%u] %s',
                   [formatDateTime('dd/mm/yy hh:nn:ss"."zzz', logTime),
                    logThreadId,
                    str]));
    //writeln(format('[%s] %s',
    //               [formatDateTime('dd/mm/yy hh:nn:ss"."zzz', logTime),
    //                str]));
    //if enableColors then
    //  textColor(LightGray);
  end;

begin
  for i := 0 to ParamCount() do
    case ParamStr(i) of
      '--colorless':
        enableColors := False;
    end;

  if not fileExists('./bot.cfg') then
  begin
    writeLn('ERROR: Config "bot.cfg" not exist!');
    halt(1);
  end;

  assignFile(configFile, './bot.cfg');
  configText := '';
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

