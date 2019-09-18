program KBot6;

{$linklib m}
{$linklib pthread}

uses
  {$ifdef unix}cthreads,{$endif} fpjson, sysutils, libcurl,
  Net, Utils, VKAPI, Commands, Database, LuaPlugins, PythonPlugins;


var
  response: TResponse;
  lpResponse, lpInfo: TJSONObject;
  msg: TJSONObject;
  lpUpdate: TJSONEnum;

begin
  logWrite('KBot6 Unified by Augmeneco');
  logWrite('Initilizing...');

  if not directoryExists('./plugins/') then
    createDir('./plugins/');

  luaLoadPlugins();
  pythonLoadPlugins();

  lpInfo := callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]);
  logWrite('New longpoll info received');
  logWrite('KBot6 ready to work');
  while true do
  begin
    response := get(format('%s?act=a_check&key=%s&ts=%s&wait=25', [lpInfo['server'].asString,
                                                                   lpInfo['key'].asString,
                                                                   lpInfo['ts'].asString]));
    if response.code = CURLE_OPERATION_TIMEOUTED then
    begin
      lpInfo := callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]);
      logWrite('New longpoll info received');
      continue;
    end;
    lpResponse := TJSONObject(getJSON(response.text));
    if lpResponse.indexOfName('failed') <> -1 then
    begin
      lpInfo := callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]);
      logWrite('New longpoll info received');
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
            logWrite('Произошла ошибка: '+E.ToString(), TLogType.logError);
        end;
      end;
    end;
  end;
end.

