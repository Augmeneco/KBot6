unit Commands;

interface

  uses
     fpjson;

  type
    THandler = class
      public
        name: String;
        procedure handler(msg: TJSONObject); virtual;
    end;
    TCommand = class (THandler)
      public
        keywords: Array of String;
        level: Byte;
        //procedure handler(msg: TJSONObject); virtual;
    end;

  var
    commandsArray: Array of TCommand;
    handlers: Array of THandler;

  procedure commandsHandler(msg: TJSONObject);


implementation
  uses
    sysutils, strutils, FLRE,
    Database, Utils;

  type
    TPack = record
      handler: THandler;
      msg: TJSONObject;
    end;
    PTPack = ^TPack;

  var
    regexCmdStr: TFLRE;

  //procedure TCommand.handler(msg: TJSONObject); begin end;
  procedure THandler.handler(msg: TJSONObject); begin end;

  function thread(pack: Pointer): ptrint;
  begin
    logThreadId := PTPack(pack)^.msg.integers['local_id'];
    try
      PTPack(pack)^.handler.handler(PTPack(pack)^.msg);
    except
      on e: Exception do
        logWrite(format('Error while processing message in thread: "%s".%sMSGOBJ: %s',
                        [e.toString(), LineEnding, PTPack(pack)^.msg.asJSON]), TLogType.logError);
    end;
    dispose(PTPack(pack));
    exit(0);
  end;

  function veryBadToLower(str: String): String;
  const
    convLowers: Array [0..87] of String = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
    	'v', 'w', 'x', 'y', 'z', 'à', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',
    	'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж',
    	'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ъ', 'ы',
    	'ь', 'э', 'ю', 'я');
    convUppers: Array [0..87] of String = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    	'V', 'W', 'X', 'Y', 'Z', 'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',
    	'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж',
    	'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ъ',
    	'Ь', 'Э', 'Ю', 'Я');
  var
    i: Integer;
  begin
    result := str;
    for i := 0 to 87 do
      result := stringReplace(result, convUppers[i], convLowers[i], [rfReplaceAll]);
  end;

  function unescapeHTML ( const S : String ) : String;
  begin
    Result := StringReplace(s,      '&lt;',   '<', [rfReplaceAll]);
    Result := StringReplace(Result, '&gt;',   '>', [rfReplaceAll]);
    Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
    Result := StringReplace(Result, '&#39;',  #39, [rfReplaceAll]);
    Result := StringReplace(Result, '&apos;', #39, [rfReplaceAll]);
    Result := StringReplace(Result, '&amp;',  '&', [rfReplaceAll]);
    Result := StringReplace(Result, '<br/>',  LineEnding, [rfReplaceAll]);
  end;

  procedure commandsHandler(msg: TJSONObject);
  var
    parts : TFLREMultiStrings = nil;
    names: Array of String;
    textWithoutSlash: String;
    cmd: TCommand;
    handler: THandler;
    dbResponse: TJSONArray;
    enum: TJSONEnum;
    pack: PTPack;
    i: Integer;
  begin
    msg.integers['local_id'] := msg.integers['date']+msg.integers['peer_id']+msg.integers['from_id'];

    if (msg['peer_id'].asInteger > 0) and (msg['peer_id'].asInteger < 2000000000) then
      msg.add('chat_type', 'private')
    else if msg['peer_id'].asInteger > 2000000000 then
      msg.add('chat_type', 'dialog')
    else if msg['peer_id'].asInteger < 0 then
      msg.add('chat_type', 'group_private');

    if msg.indexOfName('text') <> -1 then
      msg.strings['text'] := unescapeHTML(msg.strings['text'])
    else
      msg.add('text', '');

    dbResponse := dbExecOut('SELECT * FROM users WHERE id='+msg.integers['from_id'].toString()+';');
    if dbResponse.count >= 1 then
      msg.add('dbuser', dbResponse.objects[0])
    else
    begin
      dbExecIn('INSERT INTO users (id, perm, data, money) VALUES ('+msg.integers['from_id'].toString()+', 1, "{}", 100);');
      dbResponse := dbExecOut('SELECT * FROM users WHERE id='+msg.integers['from_id'].toString()+';');
      msg.add('dbuser', dbResponse.objects[0])
    end;

    for handler in handlers do
      if handler.name = dbResponse.objects[0].strings['handler'] then
      begin
        //logWrite(format('Bot mentioned by id%d in %d. Info { Text: "%s", AttachCount: %d }',
        //                [msg.integers['from_id'],
        //                 msg.integers['peer_id'],
        //                 msg.strings['text'],
        //                 msg.arrays['attachments'].count]));
        handler.handler(msg);
        exit;
      end;

    textWithoutSlash := msg.strings['text'];
    //if length(msg.strings['text']) <> 0 then
    //  if msg.strings['text'][1] = '/' then
    //    textWithoutSlash := copy(msg.strings['text'], 2, length(msg.strings['text']));

    if length(textWithoutSlash) = 0 then
      exit;

    setLength(names, 0);
    for enum in config.arrays['names'] do
    begin
      setLength(names, length(names)+1);
      names[high(names)] := veryBadToLower(enum.value.asString);
    end;

    if regexCmdStr.UTF8ExtractAll(textWithoutSlash, parts)
       and (((length(parts[0][2]) > 0) and (strToInt(parts[0][2]) = config.integers['group_id']))
            or AnsiMatchStr(veryBadToLower(parts[0][1]), names)
            or (not AnsiMatchStr(veryBadToLower(parts[0][1]), names) and (msg.strings['chat_type'] = 'private'))) then
    begin
      //ИСПРАВЬ НАХУЙ БЛЯ ЙОПТА, ВЗЯЛ ВСЮ РАБОТУ БОТА ОСТАНОВИЛ ПИСЬКА
      if (msg.strings['chat_type'] = 'dialog') or (AnsiMatchStr(veryBadToLower(parts[0][1]), names) and (msg.strings['chat_type'] = 'private')) then
      begin
        msg.add('prefix', parts[0][1]);
        msg.add('command', parts[0][3]);
        msg.add('argument', parts[0][4]);
      end
      else
      begin
        msg.add('prefix', '');
        msg.add('command', parts[0][1]);
        msg.add('argument', parts[0][3]);
      end;
    end
    else
    begin
      // Free regexp memory
      for i := 0 to length(parts)-1 do
          setLength(parts[i], 0);
      parts := nil;

      exit;
    end;

    // Free regexp memory
    for i := 0 to length(parts)-1 do
        setLength(parts[i], 0);
    parts := nil;

    logWrite(format('Mentioned by %d in %d. Info{Text: "%s", AttachCount: %d, ID: %u}',
                    [msg.integers['from_id'],
                     msg.integers['peer_id'],
                     msg.strings['text'],
                     msg.arrays['attachments'].count,
                     msg.integers['local_id']]));

    for cmd in commandsArray do
    begin
      if ansiMatchStr(veryBadToLower(msg['command'].asString), cmd.keywords) and (dbResponse.objects[0].integers['perm'] >= cmd.level) then
      begin
        pack := new(PTPack);
        pack^.handler := cmd;
        pack^.msg := msg;
        beginThread(@thread, pack);
      end;
    end;
  end;

begin
  regexCmdStr := TFLRE.create('^\s*(\[club(\d+)\|\s*\S+\s*\]|\S+)(?:\s+(\S+)|\s*$)(?:\s+(\S.*)$|\s*$)',
                              [ rfUTF8, rfSINGLELINE ]);
end.

