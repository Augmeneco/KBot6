unit PythonPlugins;

interface

  procedure pythonLoadPlugins();


implementation
    uses
      sysutils, dynlibs, fpjson, process,
      PythonEngine,
      Commands, Utils, Database, VKAPI;

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
      obj, childObj: PPyObject;
    begin
      if json.JSONType = TJSONtype.jtObject then
        obj := py.PyDict_New()
      else if json.JSONType = TJSONtype.jtArray then
        obj := py.PyList_New(0);

      for enum in json do
      begin
        case enum.value.JSONType of
          TJSONtype.jtNull:
            childObj := py.Py_None;

          TJSONtype.jtBoolean:
            if enum.value.asBoolean then
              childObj := PPyObject(py.Py_True)
            else
              childObj := PPyObject(py.Py_False);

          TJSONtype.jtNumber:
            if TJSONNumber(enum.value).NumberType = TJSONNumberType.ntFloat then
              childObj := py.PyFloat_FromDouble(enum.value.asFloat)
            else
              childObj := py.PyLong_FromLongLong(enum.value.asInt64);

          TJSONtype.jtString:
            childObj := py.PyUnicode_FromWideString(enum.value.AsUnicodeString);

          TJSONtype.jtObject:
            childObj := JSONtoPyObj(enum.value);

          TJSONtype.jtArray:
            childObj := JSONtoPyObj(enum.value);
        end;

        if json.JSONType = TJSONtype.jtObject then
          py.PyDict_SetItemString(obj, PChar(enum.key), childObj)
        else if json.JSONType = TJSONtype.jtArray then
          py.PyList_Append(obj, childObj);

        result := obj;
      end;
    end;

    procedure TPythonCommand.handler(msg: TJSONObject);
    var
      arglist: PPyObject;
    begin
      arglist := py.Py_BuildValue('(O)', JSONtoPyObj(msg));
      py.PyObject_CallObject(self.handlerObj, arglist);
      py.Py_DECREF(arglist);
    end;

    procedure TPythonHandler.handler(msg: TJSONObject);
    var
      arglist: PPyObject;
    begin
      arglist := py.Py_BuildValue('(O)', JSONtoPyObj(msg));
      py.PyObject_CallObject(self.handlerObj, arglist);
      py.Py_DECREF(arglist);
    end;

    function registerHandlerPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      nameP: PChar;
      nameLen: Integer;
      handlerObj: PPyObject;
      hndlr: TPythonHandler;
    begin
        py.PyArg_ParseTuple(args, 's#O', @nameP, @nameLen, @handlerObj);
        writeln('1');

        setLength(hndlr.name, nameLen);
        hndlr.name := nameP;
        writeln('2');

        hndlr.handlerObj := handlerObj;
        py.Py_INCREF(hndlr.handlerObj);
        writeln('3');

        Result := py.Py_None;
        py.Py_IncRef(Result);
        writeln('4');
    end;

    function registerCommandPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      cmdObj, levelObj, kwObj, handlerObj: PPyObject;
      cmd: TPythonCommand;
      keywordObj: PPyObject;
      i: Integer;
    begin
      py.PyArg_ParseTuple(args, 'O', cmdObj);

      levelObj := py.PyObject_GetAttrString(cmdObj, 'level');
      cmd.level := py.PyLong_AsLongLong(levelObj);

      kwObj := py.PyObject_GetAttrString(cmdObj, 'keywords');
      for i := 0 to py.PyList_Size(kwObj)-1 do
      begin
        setLength(cmd.keywords, length(cmd.keywords)+1);
        keywordObj := py.PyList_GetItem(kwObj, i);
        cmd.keywords[high(cmd.keywords)] := py.PyUnicode_AsWideString(keywordObj);
      end;

      cmd.handlerObj := py.PyObject_GetAttrString(cmdObj, 'handler');
      py.Py_INCREF(cmd.handlerObj);

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
    end;

    function vkApiPython(self, args: PPyObject) : PPyObject; cdecl;
    var
      method: String;
      methodP: PChar;
      methodLen: Integer;
      parametersObj: PPyObject;
      parameters: Array of String;
      key, value: PPPyObject;
      idx: PNativeInt;
      response: TJSONObject;
    begin
        parametersObj := nil;
        py.PyArg_ParseTuple(args, 's#|O', @methodP, @methodLen, @parametersObj);
        setLength(method, methodLen);
        method := methodP;
        if (parametersObj <> nil) and
           py.PyDict_Check(parametersObj) and
           (py.PyDict_Size(parametersObj) <> 0) then
          while Boolean(py.PyDict_Next(parametersObj, idx, key, value)) do
          begin
            setLength(parameters, length(parameters)+2);
            parameters[high(parameters)-1] := py.PyUnicode_AsWideString(key^);
            parameters[high(parameters)] := py.PyUnicode_AsWideString(value^);
          end;

        response := callVkApi(method, parameters);

        result := JSONtoPyObj(response);
        py.Py_IncRef(result);
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
    begin
      logWrite('Create python instance...');
      py := TPythonEngine.Create(Nil);

      py.DllName := 'libpython3.7m.so';
      runCommand('find /usr/lib -name '+py.DllName, ldConfOutput);
      py.DllPath := ldConfOutput.split(LineEnding)[0].replace(py.DllName, '');
      logWrite('Load python library "'+py.DllName+'" from "'+py.DllPath+'"');

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
          //py.PyImport_ExecCodeModule(pluginName, pModule);
        until findNext(fSearchRes) <> 0;
      findClose(fSearchRes);
    end;

end.

