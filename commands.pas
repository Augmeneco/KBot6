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
    RegExpr, sysutils, strutils,
    Database, Utils;

  type
    TPack = record
      handler: THandler;
      msg: TJSONObject;
    end;
    PTPack = ^TPack;

  //procedure TCommand.handler(msg: TJSONObject); begin end;
  procedure THandler.handler(msg: TJSONObject); begin end;

  function thread(pack: Pointer): ptrint;
  begin
    //logThreadId := PTPack(pack)^.msg.integers[thre];
    try
      PTPack(pack)^.handler.handler(PTPack(pack)^.msg);
    except
      on e: Exception do
        logWrite(format('Error while processing message in thread: "%s".%s MSGOBJ: %s',
                        [e.toString(), LineEnding, PTPack(pack)^.msg.asJSON]), TLogType.logError);
    end;
    dispose(PTPack(pack));
    exit(0);
  end;

  function unescapeHTML ( const S : String ) : String;
  begin
    Result := StringReplace(s,      '&lt;',   '<', [rfReplaceAll]);
    Result := StringReplace(Result, '&gt;',   '>', [rfReplaceAll]);
    Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
    Result := StringReplace(Result, '&#39;',  #39, [rfReplaceAll]);
    Result := StringReplace(Result, '&apos;', #39, [rfReplaceAll]);
    Result := StringReplace(Result, '&amp;',  '&', [rfReplaceAll]);
  end;

  procedure commandsHandler(msg: TJSONObject);
  var
    regex: TRegExpr;
    textWithoutSlash: String;
    cmd: TCommand;
    handler: THandler;
    dbResponse: TJSONArray;
    found: Boolean;
    enum: TJSONEnum;
    cmdName: String;
    pack: PTPack;
    threadId: TThreadID;
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
    if length(msg.strings['text']) <> 0 then
      if msg.strings['text'][1] = '/' then
        textWithoutSlash := copy(msg.strings['text'], 2, length(msg.strings['text']));

    regex := TRegExpr.create();
    regex.expression := '(\[club(\d+)\|\s*\S+\s*\]).*';

    if length(textWithoutSlash) = 0 then
      exit;

    found := false;
    for enum in config.arrays['names'] do
      if 0=CompareStr(enum.value.asString, UTF8String(textWithoutSlash.split(' ')[0])) then
      begin
        found := true;
        break;
      end;
    if found then
    begin
      msg.add('prefix', textWithoutSlash.split(' ')[0].trim());
      if length(textWithoutSlash.split(' ')) >= 2 then
        msg.add('command', textWithoutSlash.split(' ')[1].trim())
      else
        msg.add('command', '');
      if length(textWithoutSlash.split(' ')) >= 3 then
        msg.add('argument', ''.join(' ', textWithoutSlash.split(' '), 2, length(textWithoutSlash.split(' '))-2).trim())
      else
        msg.add('argument', '');
    end
    else if regex.exec(textWithoutSlash) and
            (regex.match[2].toInteger() = config.integers['group_id']) then
    begin
      msg.add('prefix', regex.match[2]);
      if length(textWithoutSlash.split(' ')) >= 2 then
        msg.add('command', textWithoutSlash.replace(regex.match[1], '').split(' ')[1].trim())
      else
        msg.add('command', '');
      if length(textWithoutSlash.split(' ')) >= 3 then
        msg.add('argument', ''.join(' ', textWithoutSlash.replace(regex.match[1], '').split(' '), 2, length(textWithoutSlash.replace(regex.match[1], '').split(' '))-3).trim())
      else
        msg.add('argument', '');
    end
    else
      if msg.strings['chat_type'] = 'private' then
      begin
        msg.add('prefix', '');
        if length(textWithoutSlash.split(' ')) >= 2 then
          msg.add('command', textWithoutSlash.split(' ')[0].trim())
        else
          msg.add('command', '');
        if length(textWithoutSlash.split(' ')) >= 3 then
          msg.add('argument', ''.join(' ', textWithoutSlash.split(' '), 1, length(textWithoutSlash.split(' '))-2).trim())
        else
          msg.add('argument', '');
      end
      else
      begin
        regex.free();
        exit;
      end;
    regex.free();

    logWrite(format('Mentioned by id%d in %d. Info { Text: "%s", AttachCount: %d }',
                    [msg.integers['from_id'],
                     msg.integers['peer_id'],
                     msg.strings['text'],
                     msg.arrays['attachments'].count]));

    for cmd in commandsArray do
    begin
      found := false;
      for cmdName in cmd.keywords do
        if 0=CompareStr(msg['command'].asString, cmdName) then
        begin
          found := true;
          break;
        end;
      if found and (dbResponse.objects[0].integers['perm'] >= cmd.level) then
      begin
        pack := new(PTPack);
        pack^.handler := cmd;
        pack^.msg := msg;
        threadId := msg.integers['local_id'];
        beginThread(@thread, pack, threadId);
      end;
    end;
  end;
end.

