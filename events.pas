unit Events;

interface

uses
  fgl, SysUtils;

  procedure registerEventHandler(handler: function(args: Array of Const): Boolean;
                                 argsForHandler: Array of Const);

implementation

type
  TEvent = class
    handlers: Array of Function(args: Array of Const): Boolean;
    procedure call();
  end;

  TEventsMap = specialize TFPGMap<String, TEvent>;


  procedure registerEventHandler(handler: function(args: Array of Const): Boolean;
                                 argsForHandler: Array of Const);

end.

