unit LuaPlugins;

interface
  uses
    lua, lualib, lauxlib, fgl, sysutils;

  type
    TPointerMap = specialize TFPGMap<String, Pointer>;

  var
    mainLuaState: Plua_State;
    mainLuaMutex: TRTLCriticalSection;

  procedure luaGetPath(pathString: String);
  procedure luaLoadPlugins();


implementation
  uses
    fpjson,
    Commands, Database, VKAPI, Utils;

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

  procedure JSONtoTable(luaState: Plua_State; json: TJSONData);
  var
    enum: TJSONEnum;
    tableRef: Integer;
  begin
    for enum in json do
    begin
      case enum.value.JSONType of
        TJSONtype.jtNull:
        begin
          lua_pushnil(luaState);

          if json.JSONType = TJSONtype.jtArray then
            lua_rawseti(luaState, -2, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_setfield(luaState, -2, PChar(enum.key));
        end;

        TJSONtype.jtBoolean:
        begin
          lua_pushboolean(luaState, enum.value.asBoolean);

          if json.JSONType = TJSONtype.jtArray then
            lua_rawseti(luaState, -2, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_setfield(luaState, -2, PChar(enum.key));
        end;

        TJSONtype.jtNumber:
        begin
          lua_pushnumber(luaState, Double(enum.value.asFloat));

          if json.JSONType = TJSONtype.jtArray then
            lua_rawseti(luaState, -2, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_setfield(luaState, -2, PChar(enum.key));
        end;

        TJSONtype.jtString:
        begin
          lua_pushstring(luaState, enum.value.asString);

          if json.JSONType = TJSONtype.jtArray then
            lua_rawseti(luaState, -2, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_setfield(luaState, -2, PChar(enum.key));
        end;

        TJSONtype.jtArray, TJSONtype.jtObject:
        begin
          lua_newtable(luaState);

          if json.JSONType = TJSONtype.jtArray then
            lua_rawseti(luaState, -2, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_setfield(luaState, -2, PChar(enum.key));

          tableRef := luaL_ref(luaState, LUA_REGISTRYINDEX);

          lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);

          if json.JSONType = TJSONtype.jtArray then
            lua_rawgeti(luaState, -1, enum.KeyNum)
          else if json.JSONType = TJSONtype.jtObject then
            lua_getfield(luaState, -1, PChar(enum.key));

          JSONtoTable(luaState, enum.value);
          lua_rawgeti(luaState, LUA_REGISTRYINDEX, tableRef);
          luaL_unref(luaState, LUA_REGISTRYINDEX, tableRef);
        end;
      end;
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
    JSONtoTable(L, msg);
    lua_rawgeti(L, LUA_REGISTRYINDEX, self.handlerRef);
    lua_insert(L, -2);
    if lua_pcall(L, 1, 0, 0) <> 0 then
      writeln('Error while running command: ', lua_tostring(L, -1));
  end;

  procedure TLuaHandler.handler(msg: TJSONObject);
  var
    L: Plua_State;
  begin
    enterCriticalSection(mainLuaMutex);
    L := lua_newthread(self.luaState);
    leaveCriticalSection(mainLuaMutex);

    lua_newtable(L);
    JSONtoTable(L, msg);
    lua_rawgeti(L, LUA_REGISTRYINDEX, self.handlerRef);
    lua_insert(L, -2);
    if lua_pcall(L, 1, 0, 0) <> 0 then
      writeln('Error while running handler "'+self.name+'": ', lua_tostring(L, -1));
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
      writeln('registerHandler() error: "main" is reserved handler name!');
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
    JSONtoTable(L, dbResponse);

    result := 1;
  end;

  function callVkApiLua(L: Plua_State = nil): Longint; cdecl;
  var
    method: String;
    parameters: Array of String;
    response: TJSONObject;
  begin
    method := lua_tostring(L, 1);
    setLength(parameters, 0);

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

    response := callVkApi(method, parameters);

    lua_newtable(L);
    JSONtoTable(L, response);

    result := 1;
  end;

  procedure luaLoadPlugins();
  var
    fileSearchResult: TSearchRec;
  begin
    if findFirst('./plugins/*.lua', faAnyFile, fileSearchResult) = 0 then
      repeat

        luaL_openlibs(mainLuaState);
        //создание стандартных функций
        lua_register(mainLuaState, 'reg_handler', @registerHandlerLua);
        lua_register(mainLuaState, 'reg_command', @registerCommandLua);
        lua_register(mainLuaState, 'change_handler', @changeHandlerLua);
        lua_register(mainLuaState, 'dbexec_in', @dbExecInLua);
        lua_register(mainLuaState, 'dbexec_out', @dbExecOutLua);
        lua_register(mainLuaState, 'vkapi', @callVkApiLua);
        //создание стандартных переменных
        lua_newtable(mainLuaState);
        JSONtoTable(mainLuaState, config);
        lua_setglobal(mainLuaState, 'config');

        if lua_dofile(mainLuaState, PChar('./plugins/'+fileSearchResult.name)) <> 0 then
          writeln('Error while loading plugin "', fileSearchResult.name, '": ', lua_tostring(mainLuaState, -1));;
      until findNext(fileSearchResult) <> 0;
    findClose(fileSearchResult);
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


begin
  initCriticalSection(mainLuaMutex);
  mainLuaState := luaL_newstate();
end.

