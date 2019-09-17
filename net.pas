unit Net;

interface
  type
    TResponse = record
      text: AnsiString;
      data: Array of Byte;
      code: SmallInt;
    end;

  function get(url: String): TResponse;
  function post(url: String): TResponse;


implementation
  uses
    libcurl, Classes;

  function writeFunction(pBuff: Pointer; size: Integer; nmemb: Integer; pUserData: Pointer): Integer;
  begin
    //writeLn(String(pBuff));
    //Response(pUserData).text := Response(pUserData).text + String(pBuff);
    TStream(pUserData).write(pBuff^, size*nmemb);
    writeFunction := size*nmemb;
  end;

  function get(url: String): TResponse;
  var
    bs: TBytesStream;
    resp: TResponse;
    hCurl: PCURL;
  begin
    hCurl := curl_easy_init();
    bs := TBytesStream.Create();
    if assigned(hCurl) then
    begin
      curl_easy_setopt(hCurl, CURLOPT_VERBOSE, [True]);
      curl_easy_setopt(hCurl, CURLOPT_URL, [PChar(url)]);
      curl_easy_setopt(hCurl, CURLOPT_WRITEDATA, [Pointer(bs)]);
      curl_easy_setopt(hCurl, CURLOPT_VERBOSE, [0]);
      curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, [@writeFunction]);
      resp.code := SmallInt(curl_easy_perform(hCurl));
      resp.text := String(bs.Bytes);
      resp.data := bs.Bytes;
    end;
    curl_easy_cleanup(hCurl);
    bs.Free;

    get := resp;
  end;

  function post(url: String): TResponse;
  var
    bs: TBytesStream;
    resp: TResponse;
    hCurl: PCURL;
  begin
    hCurl := curl_easy_init();
    bs := TBytesStream.Create();
    if assigned(hCurl) then
    begin
      curl_easy_setopt(hCurl, CURLOPT_VERBOSE, [True]);
      curl_easy_setopt(hCurl, CURLOPT_POST, [1]);
      curl_easy_setopt(hCurl, CURLOPT_URL, [PChar(url)]);
      curl_easy_setopt(hCurl, CURLOPT_WRITEDATA, [Pointer(bs)]);
      curl_easy_setopt(hCurl, CURLOPT_VERBOSE, [0]);
      curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, [@writeFunction]);
      resp.code := SmallInt(curl_easy_perform(hCurl));
      resp.text := String(bs.Bytes);
      resp.data := bs.Bytes;
    end;
    curl_easy_cleanup(hCurl);
    bs.Free;

    post := resp;
  end;

end.

