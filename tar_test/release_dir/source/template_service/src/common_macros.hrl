

% dns_address
-ifdef(public).
-define(DNS_ADDRESS,{"joqhome.dynamic-dns.net",42000}).
-endif.
-ifdef(private).
-define(DNS_ADDRESS,{"192.168.0.100",42000}).
-endif.
-ifdef(local).
-define(DNS_ADDRESS,{"localhost",42000}).
-endif.

% Heartbeat
-ifdef(test).
-define(HB_TIMEOUT,20*1000).
-else.
-define(HB_TIMEOUT,1*60*1000).
-endif.


