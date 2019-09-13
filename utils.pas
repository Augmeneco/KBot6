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

