unit PythonPlugins;

interface

  procedure pythonLoadPlugins();


implementation
    uses
      sysutils, fpjson, process,
      PythonEngine,
      LongpollChat, Utils, Database, VKAPI;

    type
      TPythonCommand = class (TCommand)
        handlerObj: PPyObject;
        procedure handler(msg: TJSONObject); override;
      end;
      TPythonHandler = class (THandler)
        handlerObj: PPyObject;
        procedure handler(msg: TJSONObject); override;
      end;

    var
      py: TPythonEngine;
      module: TPythonModule;

    function JSONtoPyObj(json: TJSONData): PPyObject;
    var
      enum: TJSONEnum;
      obj: PPyObject;
    begin
      case json.JSONType of
        TJSONtype.jtNull:
          exit(py.Py_None);

        TJSONtype.jtBoolean:
          if json.asBoolean then
            exit(PPyObject(py.Py_True))
          else
            exit(PPyObject(py.Py_False));

        TJSONtype.jtNumber:
          if TJSONNumber(json).NumberType = TJSONNumberType.ntFloat then
            exit(py.PyFloat_FromDouble(json.asFloat))
          else
            exit(py.PyLong_FromLongLong(json.asInt64));

        TJSONtype.jtString:
          exit(py.PyUnicode_FromWideString(json.AsUnicodeString));

        TJSONtype.jtObject:
        begin
          obj := py.PyDict_New();
          for enum in json do
          begin
            py.PyDict_SetItemString(obj, PChar(enum.key), JSONtoPyObj(enum.value))
          end;
          exit(obj);
        end;

        TJSONtype.jtArray:
        begin
          obj := py.PyList_New(0);
          for enum in json do
          begin
            py.PyList_Append(obj, JSONtoPyObj(enum.value));
          end;
          exit(obj);
        end;
      end;
    end;

    function PyObjToJSON(obj: PPyObject): TJSONData;
    var
      idx: PNativeInt;
      idx2: Integer;
      key, value: PPyObject;
    begin
      if obj = py.Py_None then
        exit(TJSONNull.Create)
      else if py.PyBool_Check(obj) then
        if Boolean(py.PyObject_IsTrue(obj)) then
          exit(TJSONBoolean.Create(true))
        else
          exit(TJSONBoolean.Create(false))
      else if py.PyLong_Check(obj) then
        exit(TJSONInt64Number.Create(py.PyLong_AsLongLong(obj)))
      else if py.PyFloat_Check(obj) then
        exit(TJSONFloatNumber.Create(py.PyFloat_AsDouble(obj)))
      else if py.PyString_Check(obj) then
        exit(TJSONString.Create(py.PyString_AsDelphiString(obj)))
      else if py.PyDict_Check(obj) then
      begin
        result := TJSONObject.Create;
        while Boolean(py.PyDict_Next(obj, idx, @key, @value)) do
          TJSONObject(result).Add(py.PyObjectAsString(key), PyObjToJSON(value));
      end
      else if py.PyList_Check(obj) then
      begin
        result := TJSONArray.Create;
        for idx2 := 0 to py.PyList_Size(obj) - 1 do
          TJSONArray(result).Add(PyObjToJSON(py.PyList_GetItem(obj, idx2)));
      end;
    end;


    procedure TPythonCommand.handler(msg: TJSONObject);
    var
      arglist: PPyObject;
      gil: PyGILState_STATE;
    begin
      gil := py.PyGILState_Ensure();
      arglist := py.Py_BuildValue('(O)', JSONtoPyObj(msg));
      if py.PyObject_CallObject(self.handlerObj, arglist) = nil then
        py.PyErr_Print();
      py.Py_DECREF(arglist);
      py.PyGILState_Release(gil);
    end;

    procedure TPythonHandler.handler(msg: TJSONObject);
    var
      arglist: PPyObject;
      gil: PyGILState_STATE;
    begin
      gil := py.PyGILState_Ensure();
      arglist := py.Py_BuildValue('(O)', JSONtoPyObj(msg));
      if py.PyObject_CallObject(self.handlerObj, arglist) = nil then
        py.PyErr_Print();
      py.Py_DECREF(arglist);
      py.PyGILState_Release(gil);
    end;

    function registerHandlerPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      nameP: PChar;
      nameLen: Integer;
      handlerObj: PPyObject;
      hndlr: TPythonHandler;
    begin
        hndlr := TPythonHandler.Create();
        py.PyArg_ParseTuple(args, 's#O', @nameP, @nameLen, @handlerObj);

        setLength(hndlr.name, nameLen);
        hndlr.name := nameP;

        hndlr.handlerObj := handlerObj;
        py.Py_INCREF(hndlr.handlerObj);

        //add critical sections!!!!!!!!
        setLength(handlers, length(handlers)+1);
        handlers[high(handlers)] := hndlr;

        Result := py.Py_None;
        py.Py_IncRef(Result);
    end;

    function registerCommandPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      cmdObj, levelObj, kwObj: PPyObject;
      cmd: TPythonCommand;
      keywordObj: PPyObject;
      i: Integer;
    begin
      cmd := TPythonCommand.Create();
      py.PyArg_ParseTuple(args, 'O', @cmdObj);

      py.PyObjectAsString(cmdObj);

      levelObj := py.PyObject_GetAttrString(cmdObj, 'level');
      cmd.level := py.PyLong_AsLongLong(levelObj);

      kwObj := py.PyObject_GetAttrString(cmdObj, 'keywords');
      for i := 0 to py.PyList_Size(kwObj)-1 do
      begin
        setLength(cmd.keywords, length(cmd.keywords)+1);
        keywordObj := py.PyList_GetItem(kwObj, i);
          cmd.keywords[high(cmd.keywords)] := UTF8Encode(py.PyUnicode_AsWideString(py.PyObject_Str(keywordObj)));
      end;

      cmd.handlerObj := py.PyObject_GetAttrString(cmdObj, 'handler');
      py.Py_INCREF(cmd.handlerObj);

      // ADD CRITICAL SECTIONS!!!!!!!
      setLength(commandsArray, length(commandsArray)+1);
      commandsArray[high(commandsArray)] := cmd;

      Result := py.Py_None;
      py.Py_IncRef(Result);
    end;

    function changeHandlerPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      handlerName: String;
      handlerNameP: PChar;
      handlerNameLen: Integer;
      userId: Integer;
      handler: THandler;
    begin
        py.PyArg_ParseTuple(args, 'is#', @userId, @handlerNameP, @handlerNameLen);
        setLength(handlerName, handlerNameLen);
        handlerName := handlerNameP;

        if handlerName = 'main' then
          dbExecIn('UPDATE users SET handler="main" WHERE id="'+intToStr(userId)+'";')
        else
          for handler in handlers do
            if handler.name = handlerName then
            begin
              dbExecIn('UPDATE users SET handler="'+handlerName+'" WHERE id="'+intToStr(userId)+'";');
              break;
            end;

        Result := py.Py_None;
        py.Py_IncRef(Result);
    end;

    function dbExecInPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      query: String;
      queryP: PChar;
      queryLen: Integer;
    begin
        py.PyArg_ParseTuple(args, 's#', @queryP, @queryLen);
        setLength(query, queryLen);
        query := queryP;

        dbExecIn(query);

        Result := py.Py_None;
        py.Py_IncRef(Result);
    end;

    function dbExecOutPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      query: String;
      queryP: PChar;
      queryLen: Integer;
      dbResponse: TJSONArray;
    begin
        py.PyArg_ParseTuple(args, 's#', @queryP, @queryLen);
        setLength(query, queryLen);
        query := queryP;

        dbResponse := dbExecOut(query);

        result := JSONtoPyObj(dbResponse);
        py.Py_IncRef(result);

        FreeAndNil(dbResponse);
    end;

    function vkApiPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      method: String;
      methodP: PChar;
      methodLen: Integer;
      parametersObj: PPyObject;
      parameters: Array of String;
      key, value: PPyObject;
      idx: PNativeInt;
      idx2: Int64 = 0;
      response: TJSONData;
    begin
        parametersObj := nil;
        setLength(parameters, 0);
        py.PyArg_ParseTuple(args, 's#|O', @methodP, @methodLen, @parametersObj);
        setLength(method, methodLen);
        method := methodP;
        if (parametersObj <> nil) and
           py.PyDict_Check(parametersObj) and
           (py.PyDict_Size(parametersObj) <> 0) then
        begin
          idx := @idx2;
          while Boolean(py.PyDict_Next(parametersObj, idx, @key, @value)) do
          begin
            setLength(parameters, length(parameters)+2);
            parameters[high(parameters)-1] := UTF8Encode(py.PyUnicode_AsWideString(py.PyObject_Str(key)));
            parameters[high(parameters)] := UTF8Encode(py.PyUnicode_AsWideString(py.PyObject_Str(value)));
          end;
        end;

        response := callVkApi(method, parameters);

        result := JSONtoPyObj(response);
        py.Py_IncRef(result);

        FreeAndNil(response);
        SetLength(parameters, 0);
    end;

    function logWritePython(self, args: PPyObject) : PPyObject; cdecl;
    var
      strP, logTypeStrP: PChar;
      strL, logTypeStrL: Integer;
      str, logTypeStr: String;
      logType: TLogType;
    begin
      logTypeStrP := nil;
      py.PyArg_ParseTuple(args, 's#|s#', @strP, @strL, @logTypeStrP, @logTypeStrL);
      setLength(str, strL);
      str := strP;
      if logTypeStrP <> nil then
      begin
        setLength(logTypeStr, logTypeStrL);
        logTypeStr := logTypeStrP;
      end;

      case logTypeStr of
        'normal': logType := TLogType.logNormal;
        'good': logType := TLogType.logGood;
        'error': logType := TLogType.logError;
        'warning': logType := TLogType.logWarning;
        else logType := TLogType.logNormal;
      end;

      logWrite(str, logType);

      result := py.Py_None;
      py.Py_IncRef(result);
    end;

    procedure pythonLoadPlugins();
    var
      fSearchRes: TSearchRec;
      pName, pModule: PPyObject;
      pluginName: String;
      ldConfOutput: String;
      thread: PPyThreadState;
    begin
      logWrite('Create python instance...');
      py := TPythonEngine.Create(Nil);

      py.DllName := 'libpython3.7m.so';
      runCommand('find /usr/lib -name '+py.DllName, ldConfOutput);
      py.DllPath := ldConfOutput.split(LineEnding)[0].replace(py.DllName, '');
      logWrite('Loading python library: "'+py.DllPath+py.DllName+'"');

      // создание модуля kb и создание его функций
      module:= TPythonModule.Create(nil);
      module.Engine := py;
      module.ModuleName := 'kb';
      module.AddMethod('reg_handler', @registerHandlerPython, 'Register new handler function');
      module.AddMethod('reg_command', @registerCommandPython, 'Register new command');
      module.AddMethod('change_handler', @changeHandlerPython, 'Change handler for VKID');
      module.AddMethod('dbexec_in', @dbExecInPython, 'Main database SQL query IN');
      module.AddMethod('dbexec_out', @dbExecOutPython, 'Main database SQL query OUT');
      module.AddMethod('vkapi', @vkApiPython, 'Request to VK API');
      module.AddMethod('log_write', @logWritePython, 'Write text to log');

      // init python
      py.LoadDll();

      //создание переменных модуля kb
      module.SetVar('CONFIG', JSONtoPyObj(config));
      module.SetVar('config', JSONtoPyObj(config));

      py.PyRun_SimpleString('import sys');
      py.PyRun_SimpleString('sys.path.append("./plugins")');
      py.PyRun_SimpleString('sys.dont_write_bytecode = True');

      logWrite('Python instance created');

      if findFirst('./plugins/*.py', faAnyFile, fSearchRes) = 0 then
        repeat
          pluginName := copy(fSearchRes.name, 0, length(fSearchRes.name)-3);
          logWrite('Loading and initilizing python plugin: '+pluginName);
          pName := py.PyUnicode_FromWideString(pluginName);
          pModule := py.PyImport_Import(pName);
          if pModule = nil then
          begin
            py.PyErr_Print();
            halt();
          end;
        until findNext(fSearchRes) <> 0;
      findClose(fSearchRes);

      thread := py.PyEval_SaveThread();
    end;

end.

