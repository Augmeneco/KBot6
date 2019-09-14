unit Utils;

interface

  uses
    fpjson, jsonparser;

  var
    config: TJSONObject;


implementation
  uses
    sysutils;

  var
    configFile: TextFile;
    configText, buffer: String;

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

