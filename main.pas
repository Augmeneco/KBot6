program KBot6;


{$linklib m}
{$linklib pthread}

uses
  {$ifdef unix}cthreads,{$endif} fpjson, sysutils, libcurl, dateutils,
  Net, Utils, VKAPI, Commands, Database, LuaPlugins, PythonPlugins;


var
  response: TResponse;
  lpInfo, lpResponse: TJSONObject;
  msg: TJSONObject;
  lpUpdate: TJSONEnum;

{$R *.res}

begin
  logThreadId := 0;
  botStartTime := dateTimeToUnix(Now());
  logWrite('KBot6 Unified by Augmeneco');
  logWrite('Initilizing...');

  if not directoryExists('./plugins/') then
    createDir('./plugins/');

  luaLoadPlugins();
  pythonLoadPlugins();

  lpInfo := TJSONObject(callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]));
  logWrite('New longpoll info received');
  logWrite('KBot6 ready to work');
  while true do
  begin
    response := get(format('%s?act=a_check&key=%s&ts=%s&wait=25', [lpInfo['server'].asString,
                                                                   lpInfo['key'].asString,
                                                                   lpInfo['ts'].asString]));
    if response.code = CURLE_OPERATION_TIMEOUTED then
    begin
      lpInfo := TJSONObject(callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]));
      logWrite('New longpoll info received');
      continue;
    end;
    lpResponse := TJSONObject(getJSON(response.text));
    if lpResponse.indexOfName('failed') <> -1 then
    begin
      lpInfo := TJSONObject(callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]));
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
          on e: Exception do
            logWrite('Error occurred while message processing: '+E.ToString(), TLogType.logError);
        end;
      end;
    end;
  end;
end.

