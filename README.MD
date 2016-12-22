# erltls

*TLS/SSL OpenSSL-based NIF library for Erlang using the same interface as erlang `ssl` module.*
      
This module contains interface functions for the SSL/TLS protocol. 
At this moment not all methods available in [`ssl`][1] module are implemented and also not all `ssl_option` are supported.

### Implementation notes

The library is implemented in top of `gen_tcp` and `OpenSSL` API. Because `SSL_*` API is not thread safe in order to make sure
that all calls for the same socket are not executed concurrently each socket has a gen_server to interact with native layer.
This way we don't have to use any kind of locking at native level. Also read/write operations are not taking place in the
`gen_server` process, they take place in calling process, in order to avoid gen_server to become a bottleneck for the socket. 
   
### User guide

Add `erltls` as a rebar dependency to your project:

```
{deps, [
  {erltls, ".*", {git, "https://github.com/silviucpp/erltls.git", "master"}},
}.
```

Now you can use `erltls` module the same way you are using `ssl`:

```erlang
%% server side

erltls:start(),
{ok, ListenSocket} = erltls:listen(9999, [
    {certfile, "test/server.pem"},
    {reuseaddr, true}
]),

{ok, Socket} = erltls:transport_accept(ListenSocket),
ok = erltls:ssl_accept(Socket),
ok = erltls:setopts(Socket, [{active, once}]),
receive AMessage -> io:format("recv:~p~n", [AMessage]) end,
ok = erltls:close(Socket),
ok = erltls:close(ListenSocket).
```

```erlang
%% client side

erltls:start(),
{ok, Socket} = erltls:connect("localhost", 9999,  [], infinity),
ok = erltls:send(Socket, "foo"),
ok = erltls:close(Socket).
```   
   
### Supported SSL options

Currently supported options also available in erlang `ssl`:

- `{verify, verify_type()}`  
- `{certfile, path()}` (file should be in PEM format)
- `{cacerts, [path()]}`
- `{dhfile, path()}` 
- `{ciphers, ciphers()}`

Options currently related to `erltls` only:

- `{compression, compression_type()}` - disables support for SSL/TLS compression (`{compression, compression_none}`)

### Unsupported SSL methods:

- `versions/1`
- `shutdown/2`
- `renegotiate/1`
- `prf/5`
- `peercert/1`
- `negotiated_protocol/1`
- `format_error/1`
- `eccs/1`
- `eccs/0`
- `connection_information/1`
- `connection_information/2`
- `close/2`

### Known limitations

- working only with `{packet, 0}` inet option 
- When you use `recv/2` and `Length` > 0 it's not returning a number of bytes equal's with `Length`, basically reads `Length` bytes from
  the wire, decode them and returns the result. So it might be less bytes as time there is also the SSL/TLS record overhead counted.
- Handshake process doesn't have a timeout implemented yet. So in `connect/*` or `ssl_accept/*` the timeout param is actually 
  not counting the handshake process.

[1]:http://erlang.org/doc/man/ssl.html