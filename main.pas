program KBot6;


{$linklib m}
{$linklib pthread}

uses
  {$ifdef unix}cthreads,{$endif} fpjson, sysutils, libcurl, dateutils, fileinfo,
  baseunix, ssockets,
  Net, Utils, VKAPI, LongpollChat, Database, LuaPlugins, PythonPlugins;


var
  response: TResponse;
  lpInfo, lpResponse: TJSONObject;
  msg: TJSONObject;
  lpUpdate: TJSONEnum;
  fileVerInfo: TFileVersionInfo;

{$R *.res}

//procedure Write_Str(Len : Longint;var f : Text;const s : String); iocheck; external name 'FPC_WRITE_TEXT_SHORTSTR';

procedure sigHandler(sig: Longint); cdecl;
begin
  case sig of
    SIGTERM, SIGQUIT, SIGINT:
    begin
      //Write_Str(1, output, #10#13);
      writeln();
      halt;
    end;
  end;
end;

procedure updateLPInfo();
begin
  lpInfo := TJSONObject(callVkApi('groups.getLongPollServer', ['group_id', config['group_id'].AsString]));
  logWrite('New longpoll info received');
end;

begin
  fpsignal(SIGINT, @sigHandler);
  fpsignal(SIGTERM, @sigHandler);
  fpsignal(SIGQUIT, @sigHandler);

  {$if declared(UseHeapTrace)}deleteFile('heap.trc'); setHeapTraceOutput('heap.trc');{$endif}

  logThreadId := 0;

  botStartTime := dateTimeToUnix(Now());

  fileVerInfo := TFileVersionInfo.Create(nil);
  FileVerInfo.ReadFileInfo;
  logWrite(format('KBot6 v.%s by Augmeneco (Lanode, Cha14ka).', [fileVerInfo.VersionStrings.Values['FileVersion']]));
  FileVerInfo.Free;

  logWrite('Initilizing...');

  if not directoryExists('./plugins/') then
    createDir('./plugins/');

  luaLoadPlugins();
  pythonLoadPlugins();

  updateLPInfo();
  logWrite('KBot6 ready to work');
  while true do
  begin
    try
      response := get(format('%s?act=a_check&key=%s&ts=%s&wait=25',
                             [lpInfo['server'].asString,
                              lpInfo['key'].asString,
                              lpInfo['ts'].asString]),
                      10000);
    except
      on e: ESocketError do
      begin
        logWrite('Longpoll socket timeout!');
        updateLPInfo();
        continue;
      end;
    end;

    if response.code <> 200 then
    begin
      logWrite('Longpoll HTTP response isn''t 200 (OK)!');
      updateLPInfo();
      continue;
    end;

    lpResponse := TJSONObject(getJSON(response.text));
    //logWrite('Longpoll recieved!');
    if lpResponse.indexOfName('failed') <> -1 then
    begin
      logWrite('Longpoll JSON response is "failed"!');
      updateLPInfo();
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
      end;      {$if declared(UseHeapTrace)}dumpHeap();{$endif}
    end;
  end;
end.

