-module(erltls_record).
-author("silviu.caragea").

-export([
    get_protocol_record_header_size/1,
    read_next_record/4,
    is_dtls/1
]).

-define(RC_HEADER_SIZE_TLS, 5).
-define(RC_HEADER_SIZE_DTLS, 13).

read_next_record(TcpSocket, IsDtls, RecordHeaderSize, Timeout) ->
    case gen_tcp:recv(TcpSocket, RecordHeaderSize, Timeout) of
        {ok, RecordHeaderPacket} ->
            case get_record_header_info(IsDtls, RecordHeaderPacket) of
                {ok, Type, FgLength} ->
                    case gen_tcp:recv(TcpSocket, FgLength, Timeout) of
                        {ok, PacketFragment} ->
                            {ok, Type,  <<RecordHeaderPacket/binary, PacketFragment/binary>>};
                        Error ->
                            Error
                    end;
                Error ->
                    Error
            end;
        Error ->
            Error
    end.

% dtls header: type:uint8(21 - alert) {major:uint8 minor:uint8} epoch:uint16 sequence_number:uint48 length:uint16
% tls header:  type:uint8(21 - alert) {major:uint8 minor:uint8} length:uint16

get_record_header_info(IsDtls, HeaderBytes) ->
    case IsDtls of
        false ->
            <<Type:8/integer, _MaV:8/integer, _MiV:8/integer, FgLength:16/integer, _Rest/binary>> = HeaderBytes,
            {ok, Type, FgLength};
        _ ->
            <<Type:8/integer, _MaV:8/integer, _MiV:8/integer, _Epoch:16/integer, _Seq:48/integer, FgLength:16/integer, _Rest/binary>> = HeaderBytes,
            {ok, Type, FgLength}
    end.

get_protocol_record_header_size(dtlsv1) ->
    ?RC_HEADER_SIZE_DTLS;
get_protocol_record_header_size('dtlsv1.2') ->
    ?RC_HEADER_SIZE_DTLS;
get_protocol_record_header_size(_Protocol) ->
    ?RC_HEADER_SIZE_TLS.

is_dtls(dtlsv1) ->
    true;
is_dtls('dtlsv1.2') ->
    true;
is_dtls(_) ->
    false.