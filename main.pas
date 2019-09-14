program KBot6;

{$linklib m}
{$linklib pthread}

uses
  {$ifdef unix}cthreads,{$endif} fpjson, sysutils,
  Net, Utils, VKAPI, Commands, Database, LuaPlugins{, PythonPlugins};


var
  response: TResponse;
  lpResponse, lpInfo: TJSONObject;
  msg: TJSONObject;
  lpUpdate: TJSONEnum;

begin
  writeLn('KBot6 Unified by Augmeneco');

  if not directoryExists('./plugins/') then
    createDir('./plugins/');

  luaLoadPlugins();

  lpInfo := callVkApi('groups.getLongPollServer', ['group_id', IntToStr(158856938)]);
  while true do
  begin
    response := get(format('%s?act=a_check&key=%s&ts=%s&wait=25', [lpInfo['server'].asString,
                                                                   lpInfo['key'].asString,
                                                                   lpInfo['ts'].asString]));
    lpResponse := TJSONObject(getJSON(response.text));
    if lpResponse.indexOfName('failed') <> -1 then
    begin
      lpInfo := callVkApi('groups.getLongPollServer', ['group_id', intToStr(158856938)]);
      continue;
    end;
    lpInfo.strings['ts'] := lpResponse['ts'].asString;

    for lpUpdate in lpResponse['updates'] do
    begin
      if TJSONObject(lpUpdate.value).strings['type'] = 'message_new' then
      begin
        msg := TJSONObject(lpUpdate.value).objects['object'];

        try
          //raise Exception.create('AAA KERNEL PANIC!!!');
          commandsHandler(msg)
        except
          on E: Exception do
            writeLn('Произошла ошибка: '+E.ToString());
        end;
      end;
    end;
  end;
end.

