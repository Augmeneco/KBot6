unit VKAPI;


interface

  uses
    fpjson, jsonparser, sysutils,
    Net, Utils;

  function callVkApi(method: AnsiString; parameters: Array of AnsiString): TJSONData;
  procedure sendMsg(peer_id: Integer; text: String);


implementation

  function encodeUrl(url: string): string;
  var
    x: integer;
    sBuff: string;
  const
    SafeMask = ['A'..'Z', '0'..'9', 'a'..'z', '*', '@', '.', '_', '-'];
  begin
    //Init
    sBuff := '';

    for x := 1 to Length(url) do
    begin
      //Check if we have a safe char
      if url[x] in SafeMask then
      begin
        //Append all other chars
        sBuff := sBuff + url[x];
      end
      else if url[x] = ' ' then
      begin
        //Append space
        sBuff := sBuff + '+';
      end
      else
      begin
        //Convert to hex
        sBuff := sBuff + '%' + IntToHex(Ord(url[x]), 2);
      end;
    end;

    Result := sBuff;
  end;

  function callVkApi(method: AnsiString; parameters: Array of AnsiString): TJSONData;
  var
    params: Array of String;
    i: Integer;
    response: TResponse;
    json: TJSONObject;
  begin
    setLength(params, 2);
    params[0] := 'access_token='+config.strings['group_token'];
    params[1] := 'v=5.80';
    for i := 0 to length(parameters) - 1 do
      if i mod 2 = 0 then
      begin
        setLength(params, length(params)+1);
        params[high(params)] := parameters[i]+'='+parameters[i+1];
      end;

    response := post('https://api.vk.com/method/'+method, params, []);

    json := TJSONObject(getJSON(response.text));
    if json.indexOfName('error') <> -1 then
    begin
      writeln(format('VK ERROR #%d: "%s"'#13#10'PARAMS: %s', [json.getPath('error.error_code').asInteger,
                                                              json.getPath('error.error_msg').asString,
                                                              json.getPath('error.request_params').asJSON]));
      raise Exception.create('VK ERROR');
    end;

    result := json['response'];

    setLength(params, 0);
  end;

  procedure sendMsg(peer_id: Integer; text: String);
  begin
    callVkApi('messages.send', ['peer_id', intToStr(peer_id),
                                'message', text]);
  end;

end.

