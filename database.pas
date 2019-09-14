unit Database;

interface

  uses
    fpjson;

  procedure dbExecIn(queryString: String);
  function dbExecOut(queryString: String): TJSONArray;


implementation
  uses
    sqlite3conn, db, SQLdb;

  var
    conn: TSQLite3Connection;
    trans: TSQLTransaction;
    query: TSQLQuery;

  procedure dbExecIn(queryString: String);
  begin
    trans.startTransaction();
    conn.executeDirect(queryString);
    trans.commit();
    trans.endTransaction();
  end;

  function dbExecOut(queryString: String): TJSONArray;
  var
    response: TJSONArray;
    responseRow: TJSONObject;
    i: Integer;
  begin
    response := TJSONArray.create();
    query.SQL.text := queryString;
    query.open();
    while not query.eof do
    begin
      responseRow := TJSONObject.create();
      for i := 0 to query.fields.count-1 do
      begin
        case query.fields[i].dataType of
          TFieldType.ftInteger:
            responseRow.add(query.fields[i].fieldName, query.fields[i].asInteger);
          TFieldType.ftFloat:
            responseRow.add(query.fields[i].fieldName, query.fields[i].asFloat);
          TFieldType.ftMemo:
            responseRow.add(query.fields[i].fieldName, query.fields[i].asString);
          TFieldType.ftBlob:
            responseRow.add(query.fields[i].fieldName, query.fields[i].asInteger);
        end;
      end;
      response.add(responseRow);
      query.Next;
    end;
    query.close();
    trans.endTransaction();
    result := response;
  end;

begin
  if not fileExists('./users.db') then
  begin
    writeLn('ERROR: Database "users.db" not exist!');
    halt(1);
  end;

  conn := TSQLite3Connection.create(nil);
  conn.databaseName := './users.db';
  trans := TSQLTransaction.create(nil);
  conn.transaction := trans;
  query := TSQLQuery.create(nil);
  query.database := conn;
end.

