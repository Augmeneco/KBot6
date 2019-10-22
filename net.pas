unit Net;

interface
  uses
    classes;

  type
    TResponse = record
      text: AnsiString;
      data: Array of Byte;
      code: Integer;
    end;
    TFile = record
      name: String;
      filename: String;
      contenttype: String;
      contents: TStream;
    end;

  function get(url: String; timeout: Integer = 35): TResponse;
  function post(url: String; formData: Array of String; fileData: Array of TFile): TResponse;


implementation
  uses
    SysUtils, fphttpclient, fpopenssl, openssl;

  var
    encoder: TEncoding;

  //function writeFunction(pBuff: Pointer; size: Integer; nmemb: Integer; pUserData: Pointer): Integer;
  //begin
  //  //writeLn(String(pBuff));
  //  //Response(pUserData).text := Response(pUserData).text + String(pBuff);
  //  TStream(pUserData).write(pBuff^, size*nmemb);
  //  writeFunction := size*nmemb;
  //end;

  function get(url: String; timeout: Integer = 35): TResponse;
  var
    bs: TBytesStream;
    resp: TResponse;
    client: TFPHTTPClient;
  begin
    bs := TBytesStream.Create();
    client := TFPHttpClient.Create(nil);
    client.get(url, bs);
    resp.code := client.ResponseStatusCode;
    resp.text := encoder.GetString(bs.Bytes);
    resp.data := bs.Bytes;
    bs.Free;

    result := resp;
  end;

  function post(url: String; formData: Array of String; fileData: Array of TFile): TResponse;
  const
    CRLF = #13#10;
  var
    bs: TBytesStream;
    resp: TResponse;
    client: TFPHTTPClient;

    S, Sep : String;
    SS : TStringStream;
    I: Integer;
    N,V: String;


  begin
    bs := TBytesStream.Create();
    client := TFPHTTPClient.Create(nil);

    Sep:=Format('%.8x_multipart_boundary',[Random($ffffff)]);
    client.AddHeader('Content-Type','multipart/form-data; boundary='+Sep);
    SS:=TStringStream.Create('');
    if (length(formData)<>0) then
      for I:=0 to length(formData) -1 do
        begin
        // not url encoded
        n := copy(formData[i], 0, pos('=', formData[i])-1);
        v := copy(formData[i], pos('=', formData[i])+1, length(formData[i])-pos('=', formData[i]));
        S :='--'+Sep+CRLF;
        S:=S+Format('Content-Disposition: form-data; name="%s"'+CRLF+CRLF+'%s'+CRLF,[n, v]);
        SS.WriteBuffer(S[1],Length(S));
        end;
   if (length(fileData)<>0) then
     for I:=0 to length(fileData) -1 do
      begin
        S:='--'+Sep+CRLF;
        s:=s+Format('Content-Disposition: form-data; name="%s"; filename="%s"'+CRLF,[fileData[i].name,ExtractFileName(fileData[i].filename)]);
        s:=s+'Content-Type: '+fileData[i].contentType+CRLF+CRLF;
        SS.WriteBuffer(S[1],Length(S));
        fileData[i].contents.Seek(0, soFromBeginning);
        SS.CopyFrom(fileData[i].contents,fileData[i].contents.Size);
        S:=CRLF+'--'+Sep+'--'+CRLF;
        SS.WriteBuffer(S[1],Length(S));
      end;
    S :='--'+Sep+CRLF;
    SS.WriteBuffer(S[1],Length(S));
    SS.Position:=0;
    //writeln(ss.DataString);
    client.RequestBody:=SS;
    client.Post(url, bs);
    resp.code := client.ResponseStatusCode;
    resp.text := encoder.GetString(bs.Bytes);
    resp.data := bs.Bytes;

    bs.Free;
    client.Free;
    SS.Free;
    client.RequestBody:=Nil;

    result := resp;
  end;

initialization
begin
  encoder := TEncoding.UTF8;
end;
end.

