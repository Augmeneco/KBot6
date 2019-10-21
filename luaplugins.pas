unit LuaPlugins;

interface

  procedure luaGetPath(pathString: String);
  procedure luaLoadPlugins();


implementation
  uses
    fpjson, lua53, dynlibs, sysutils,
    Commands, Database, VKAPI, Utils, Net;

  type
    TLuaCommand = class (TCommand)
      handlerRef: Integer;
      luaState: Plua_State;
      procedure handler(msg: TJSONObject); override;
    end;
    TLuaHandler = class (THandler)
      handlerRef: Integer;
      luaState: Plua_State;
      procedure handler(msg: TJSONObject); override;
    end;

  var
    mainLuaState: Plua_State;
    mainLuaMutex: TRTLCriticalSection;

  procedure stackDump(L: Plua_State; count: Integer=5; top: Boolean=true);
  var
    i, t: Integer;
  begin
    writeln('------------------- Stack Dump --------------------');
    if top then
      for i:=-1 downto -count do
      begin
        t := lua_type(L, i);
        case t of
          LUA_TSTRING:
            writeln(i, ': "', lua_tostring(L, i), '"');
          LUA_TBOOLEAN:
            writeln(i, ': ', lua_toboolean(L, i));
          LUA_TNUMBER:
            writeln(i, ': ', lua_tonumber(L, i));
          else writeln(i, ': ', lua_typename(L, i));
        end;
      end
    else
      for i:=1 downto count do
      begin
        t := lua_type(L, i);
        case t of
          LUA_TSTRING:
            writeln(i, ': "', lua_tostring(L, i), '"');
          LUA_TBOOLEAN:
            writeln(i, ': ', lua_toboolean(L, i));
          LUA_TNUMBER:
            writeln(i, ': ', lua_tonumber(L, i));
          else writeln(i, ': ', lua_typename(L, i));
        end;
      end;
   writeln('--------------- Stack Dump Finished ---------------');
  end;

  procedure JSONtoLua(luaState: Plua_State; json: TJSONData);
  var
    enum: TJSONEnum;
    tableRef: Integer;
  begin
    case json.JSONType of
      TJSONtype.jtNull:
        lua_pushnil(luaState);
      TJSONtype.jtBoolean:
        lua_pushboolean(luaState, json.asBoolean);
      TJSONtype.jtNumber:
        lua_pushnumber(luaState, Double(json.asFloat));
      TJSONtype.jtString:
        lua_pushstring(luaState, json.asString);
      TJSONtype.jtObject:
      begin
        lua_newtable(luaState);
        tableRef := luaL_ref(luaState, LUA_REGISTRYINDEX);
        lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);
        for enum in json do
        begin
          JSONtoLua(luaState, enum.value);

          lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);

          lua_insert(luaState, -2);
          lua_setfield(luaState, -2, PChar(enum.key));
        end;
        luaL_unref(luaState, LUA_REGISTRYINDEX, tableRef);
      end;
      TJSONtype.jtArray:
      begin
        lua_newtable(luaState);
        tableRef := luaL_ref(luaState, LUA_REGISTRYINDEX);
        lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);
        for enum in json do
        begin
          JSONtoLua(luaState, enum.value);

          lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);

          lua_insert(luaState, -2);
          lua_rawseti(luaState, -2, enum.KeyNum+1);
        end;
        luaL_unref(luaState, LUA_REGISTRYINDEX, tableRef);
      end;
    end;
  end;

  function luaToJSON(luaState: Plua_State): TJSONData;
  var
    isArray: Boolean;
    obj: TJSONObject;
    arr: TJSONArray;
    tableRef: Integer;
    k, max: Double;
  begin
    if lua_isnil(luaState, -1) then
      result.Value := nil
    else if lua_isboolean(luaState, -1) then
      result.Value := lua_toboolean(luaState, -1)
    else if lua_isnumber(luaState, -1) then
      result.Value := lua_tonumber(luaState, -1)
    else if lua_isstring(luaState, -1) then
      result.Value := lua_tostring(luaState, -1)
    else if lua_istable(luaState, -1) then
    begin
      // Is not array?
      isArray := true;
      lua_pushnil(luaState);  // first key
      max := 0;
      while lua_next(luaState, -2) <> 0 do
      begin
        if lua_isnumber(luaState, -2) then
        begin
          k := lua_tonumber(luaState, -2);
          lua_pop(luaState, 1);
          // Integer >= 1 ?
          if (trunc(k) = k) and (k >= 1) then
          begin
            if k > max then
              max := k
            else
            begin
              isArray := false;
              break;
            end;
          end;
        end
        else
        begin
          isArray := false;
          break;
        end;
      end;
      lua_pop(luaState, 1);

      if isArray then
        arr := TJSONArray.Create
      else
        obj := TJSONObject.Create;

      tableRef := luaL_ref(luaState, LUA_REGISTRYINDEX);
      lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);
      lua_pushnil(luaState);  // first key
      while lua_next(luaState, -2) <> 0 do
      begin
        // uses 'key' (at index -2) and 'value' (at index -1)
        if isArray then
          arr.Add(luaToJSON(luaState))
        else
          obj.Add(lua_tostring(luaState, -2), luaToJSON(luaState));
        lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);
        //removes 'value'; keeps 'key' for next iteration
        //lua_pushstring(L, parameters[high(parameters)-1]);
        lua_pop(luaState, 1);
      end;
      lua_pop(luaState, 1);
      luaL_unref(luaState, LUA_REGISTRYINDEX, tableRef);

      if isArray then
        result := arr
      else
        result := obj;
    end;
  end;


  procedure TLuaCommand.handler(msg: TJSONObject);
  var
    L: Plua_State;
  begin
    enterCriticalSection(mainLuaMutex);
    L := lua_newthread(self.luaState);
    leaveCriticalSection(mainLuaMutex);

    lua_newtable(L);
    JSONtoLua(L, msg);
    lua_rawgeti(L, LUA_REGISTRYINDEX, self.handlerRef);
    lua_insert(L, -2);
    if lua_pcall(L, 1, 0, 0) <> 0 then
      logWrite('Error while running command: '+lua_tostring(L, -1));
  end;

  procedure TLuaHandler.handler(msg: TJSONObject);
  var
    L: Plua_State;
  begin
    enterCriticalSection(mainLuaMutex);
    L := lua_newthread(self.luaState);
    leaveCriticalSection(mainLuaMutex);

    lua_newtable(L);
    JSONtoLua(L, msg);
    lua_rawgeti(L, LUA_REGISTRYINDEX, self.handlerRef);
    lua_insert(L, -2);
    if lua_pcall(L, 1, 0, 0) <> 0 then
      logWrite('Error while running handler "'+self.name+'": '+lua_tostring(L, -1));
  end;

  function registerHandlerLua(L: Plua_State = nil): Longint; cdecl;
  var
    handler: TLuaHandler;
  begin
    handler := TLuaHandler.create();
    handler.luaState := L;

    handler.name := luaL_checkstring(L, 1);
    if handler.name = 'main' then
    begin
      logWrite('registerHandler() error: "main" is reserved handler name!');
      exit(0);
    end;

    if lua_isfunction(L, 2) then
      handler.handlerRef := luaL_ref(L, LUA_REGISTRYINDEX)
    else
      raise Exception.create('Handler is not function');

    enterCriticalSection(mainLuaMutex);
    setLength(handlers, length(handlers)+1);
    handlers[high(handlers)] := handler;
    leaveCriticalSection(mainLuaMutex);

    result := 0;
  end;

  function registerCommandLua(L: Plua_State = nil): Longint; cdecl;
  var
    command: TLuaCommand;
  begin
    command := TLuaCommand.create();

    command.luaState := L;

    if not lua_istable(L, 1) then
      raise Exception.create('Command is not table');

    lua_getfield(L, 1, 'level');
    if not lua_isnumber(L, -1) then
      raise Exception.create('Level is not number');
    command.level := trunc(lua_tonumber(L, -1));
    lua_pop(L, 1);

    lua_getfield(L, 1, 'handler');
    if not lua_isfunction(L, -1) then
      raise Exception.create('Handler is not function');
    command.handlerRef := luaL_ref(L, LUA_REGISTRYINDEX);

    lua_getfield(L, 1, 'keywords');
    if not lua_istable(L, -1) then
      raise Exception.create('Keywords is not table');
    lua_pushnil(L);  // first key
    while lua_next(L, -2) <> 0 do
    begin
      // uses 'key' (at index -2) and 'value' (at index -1)
      setLength(command.keywords, length(command.keywords)+1);
      command.keywords[high(command.keywords)] := strnew(luaL_checkstring(L, -1));
      //removes 'value'; keeps 'key' for next iteration
      lua_pop(L, 1);
    end;
    lua_pop(L, 1);

    enterCriticalSection(mainLuaMutex);
    setLength(commandsArray, length(commandsArray)+1);
    commandsArray[high(commandsArray)] := command;
    leaveCriticalSection(mainLuaMutex);

    result := 0;
  end;

  function changeHandlerLua(L: Plua_State = nil): Longint; cdecl;
  var
    userId: Integer;
    handlerId: String;
    handler: THandler;
  begin
    userId := luaL_checkinteger(L, 1);
    handlerId := luaL_checkstring(L, 2);

    if handlerId = 'main' then
      dbExecIn('UPDATE users SET handler="main" WHERE id="'+intToStr(userId)+'";')
    else
      for handler in handlers do
        if handler.name = handlerId then
        begin
          dbExecIn('UPDATE users SET handler="'+handlerId+'" WHERE id="'+intToStr(userId)+'";');
          break;
        end;
    result := 0;
  end;

  function dbExecInLua(L: Plua_State = nil): Longint; cdecl;
  var
    query: String;
  begin
    query := luaL_checkstring(L, 1);
    dbExecIn(query);

    result := 0;
  end;

  function dbExecOutLua(L: Plua_State = nil): Longint; cdecl;
  var
    query: String;
    dbResponse: TJSONArray;
  begin
    query := luaL_checkstring(L, 1);
    dbResponse := dbExecOut(query);

    lua_newtable(L);
    JSONtoLua(L, dbResponse);

    result := 1;
  end;

  function callVkApiLua(L: Plua_State = nil): Longint; cdecl;
  var
    method: String;
    parameters: Array of String;
    response: TJSONData;
  begin
    method := lua_tostring(L, 1);
    setLength(parameters, 0);

    if lua_gettop(L) >= 2 then
    begin
      lua_pushnil(L);  // first key
      while lua_next(L, 2) <> 0 do
      begin
        // uses 'key' (at index -2) and 'value' (at index -1)
        setLength(parameters, length(parameters)+1);
        parameters[high(parameters)] := lua_tostring(L, -2);

        setLength(parameters, length(parameters)+1);
        parameters[high(parameters)] := lua_tostring(L, -1);
        //removes 'value'; keeps 'key' for next iteration
        //lua_pushstring(L, parameters[high(parameters)-1]);
        lua_pop(L, 1);
      end;
      lua_pop(L, 1);
    end;

    response := callVkApi(method, parameters);

    JSONtoLua(L, response);

    result := 1;
  end;

  function getLua(L: Plua_State = nil): Longint; cdecl;
  var
    url: String;
    resp: TResponse;
  begin
    url := lua_tostring(L, 1);

    resp := get(url);

    lua_newtable(L);
    lua_pushinteger(L, Int64(resp.code));
    lua_setfield(L, -2, 'code');
    lua_pushstring(L, resp.text);
    lua_setfield(L, -2, 'text');
    lua_pushlstring(L, PChar(resp.data), length(resp.data));
    lua_setfield(L, -2, 'data');

    exit(1);
  end;

  function postLua(L: Plua_State = nil): Longint; cdecl;
  var
    url: String;
    paramsArray: Array of String;
    filesArray: Array of TFile;
    resp: TResponse;

    files: TJSONArray;
    i: Integer;
  begin
    url := lua_tostring(L, 1);

    setLength(paramsArray, 0);
    if lua_gettop(L) >= 2 then
    begin
      lua_pushnil(L);  // first key
      while lua_next(L, 2) <> 0 do
      begin
        // uses 'key' (at index -2) and 'value' (at index -1)
        setLength(paramsArray, length(paramsArray)+1);
        paramsArray[high(paramsArray)] := lua_tostring(L, -1);
        //removes 'value'; keeps 'key' for next iteration
        //lua_pushstring(L, parameters[high(parameters)-1]);
        lua_pop(L, 1);
      end;
      lua_pop(L, 1);
    end;

    setLength(filesArray, 0);
    if lua_gettop(L) >= 3 then
    begin
      lua_insert(L, 3);
      files := TJSONArray(luaToJSON(L));
      setLength(filesArray, files.Count);
      for i := 0 to length(filesArray)-1 do
      begin
        filesArray[i].name := TJSONObject(files[i])['name'].AsString;
        filesArray[i].filename := TJSONObject(files[i])['filename'].AsString;
        filesArray[i].contentType := TJSONObject(files[i])['contenttype'].AsString;
        filesArray[i].contents.writeAnsiString(TJSONObject(files[i])['contents'].AsString);
      end;
    end;

    resp := post(url, paramsArray, filesArray);

    lua_newtable(L);
    lua_pushinteger(L, Int64(resp.code));
    lua_setfield(L, -2, 'code');
    lua_pushstring(L, resp.text);
    lua_setfield(L, -2, 'text');
    lua_pushlstring(L, PChar(resp.data), length(resp.data));
    lua_setfield(L, -2, 'data');
    exit(1);
  end;

  function logWriteLua(L: Plua_State = nil): Longint; cdecl;
  var
    str, logTypeStr: String;
    logType: TLogType;
  begin
    str := lua_tostring(L, 1);
    logTypeStr := lua_tostring(L, 2);

    case logTypeStr of
      'normal': logType := TLogType.logNormal;
      'good': logType := TLogType.logGood;
      'error': logType := TLogType.logError;
      'warning': logType := TLogType.logWarning;
      else logType := TLogType.logNormal;
    end;

    logWrite(str, logType);

    result := 0;
  end;

  procedure luaLoadPlugins();
  var
    fSearchRes: TSearchRec;
    pluginName: String;
  begin
    logWrite('Create lua context...');
    initCriticalSection(mainLuaMutex);
    mainLuaState := luaL_newstate();
    luaL_openlibs(mainLuaState);
    //создание стандартных функций
    lua_register(mainLuaState, 'reg_handler', @registerHandlerLua);
    lua_register(mainLuaState, 'reg_command', @registerCommandLua);
    lua_register(mainLuaState, 'change_handler', @changeHandlerLua);
    lua_register(mainLuaState, 'dbexec_in', @dbExecInLua);
    lua_register(mainLuaState, 'dbexec_out', @dbExecOutLua);
    lua_register(mainLuaState, 'vkapi', @callVkApiLua);
    lua_register(mainLuaState, 'net_get', @getLua);
    lua_register(mainLuaState, 'net_post', @postLua);
    lua_register(mainLuaState, 'log_write', @logWriteLua);
    //создание стандартных переменных
    JSONtoLua(mainLuaState, config);
    lua_setglobal(mainLuaState, 'CONFIG');
    //JSONtoLua(mainLuaState, config);
    //lua_setglobal(mainLuaState, 'config');
    lua_pushinteger(mainLuaState, botStartTime);
    lua_setglobal(mainLuaState, 'BOT_START_TIME');

    //stackDump(mainLuaState);

    logWrite('Lua context created');

    if findFirst('./plugins/*.lua', faAnyFile, fSearchRes) = 0 then
      repeat
        pluginName := copy(fSearchRes.name, 0, length(fSearchRes.name)-4);
        logWrite('Loading and initilizing lua plugin: '+pluginName);
        if luaL_loadfile(mainLuaState, PChar('./plugins/'+fSearchRes.name)) <> 0 then
          logWrite('Error while loading plugin "'+ fSearchRes.name+ '": '+ lua_tostring(mainLuaState, -1), logError);
        if lua_pcall(mainLuaState, 0, LUA_MULTRET, 0) <> 0 then
            logWrite('Error while initing plugin "'+ fSearchRes.name+ '": '+ lua_tostring(mainLuaState, -1), logError);
      until findNext(fSearchRes) <> 0;
    findClose(fSearchRes);
  end;

  procedure luaGetPath(pathString: String);
  var
    path: array of String;
    pathItem: String;
    i, j: Integer;
  begin
    setLength(path, 1);
    j := 0;
    for i := 0 to length(pathString) do
      if pathString[i] <> '.' then
        path[j] := path[j] + pathString[i]
      else
      begin
        setLength(path, length(path)+1);
        inc(j);
      end;

    lua_getglobal(mainLuaState, PChar(path[0]));
    if lua_istable(mainLuaState, -1) then
      for pathItem in path do
      begin
        lua_pushstring(mainLuaState, PChar(pathItem));
        lua_gettable(mainLuaState, -2);  { get background[key] }
        if not lua_istable(mainLuaState, -1) then
          break;
        lua_pop(mainLuaState, 1);  { remove number }
      end;
  end;
end.

