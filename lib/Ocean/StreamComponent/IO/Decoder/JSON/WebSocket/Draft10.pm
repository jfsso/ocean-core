package Ocean::StreamComponent::IO::Decoder::JSON::WebSocket::Draft10;

use strict;
use warnings;

use Config;
use Digest::SHA1;
use MIME::Base64;
use HTTP::Parser::XS qw(parse_http_request);
use Log::Minimal;

use Ocean::Constants::StreamErrorType;
use Ocean::Constants::WebSocketOpcode;
use Ocean::Error;
use Ocean::Util::WebSocket;
use Ocean::Util::HTTPBinding;

use constant GUID => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

use constant {
    STATE_INIT       => 0,
    STATE_HANDSHAKED => 1,
};

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        _buffer        => '', 
        _message       => '',
        _state         => STATE_INIT,
        _on_handshake  => sub {},
        _on_read_frame => sub {},
        # XXX move to config?
        _masked          => $args{masked} || 0,
#        _max_buffer_size => $args{max_buffer_size} || 1024 * 600,
#        _max_packet_size => $args{max_packet_size} || 262144,
    }, $class;
    return $self;
}

sub on_handshake {
    my ($self, $callback) = @_;
    $self->{_on_handshake} = $callback;
}

sub on_read_frame {
    my ($self, $callback) = @_;
    $self->{_on_read_frame} = $callback;
}

sub reset {
    my $self = shift;
    $self->{_state} = STATE_INIT;
    $self->{_buffer} = '';
}

sub release {
    my $self = shift;
    delete $self->{_on_handshake}
        if $self->{_on_handshake};
    delete $self->{_on_read_frame}
        if $self->{_on_read_frame};
}

sub parse_more {
    my ($self, $data) = @_;
    $self->{_buffer} .= $data;
    $self->_parse();
    #if (length $self->{buffer} > $self->{_max_buffer_size}) {
    #    Ocean::Error::ProtocolError->throw;
    #}
}

sub _parse {
    my $self = shift;
    if ($self->{_state} == STATE_INIT) {
        debugf("<Stream> <Decoder> start to parse header");
        my $pos = index($self->{_buffer}, "\r\n\r\n");
        if ($pos >= 0) {
            my $header = substr($self->{_buffer}, 0, $pos + 4);
            $self->{_buffer} = substr($self->{_buffer}, $pos + 4);

            my $env = {};
            my $ret = parse_http_request($header, $env);
            unless ($ret > 0) {
                $self->reset();
                debugf("<Stream> <Decoder> Failed to parse header, '%s'", $header);

                Ocean::Error::HTTPHandshakeError->throw(
                    code => 400,
                    type => q{Bad Request}, 
                );
                return;
            }
            debugf("<Stream> <Decoder> parsed header successfully");

            if ( $env->{REQUEST_METHOD} ne 'GET') {
                $self->reset();
                debugf("<Stream> <Decoder> invalid request method, '%s'", $header);
                Ocean::Error::HTTPHandshakeError->throw(
                    code => 400,
                    type => q{Bad Request}, 
                );
            }

            # TODO
            #if ( $env->{HTTP_HOST} eq $self->{_domain}) {
            #    $self->reset();
            #    debugf("<Stream> <Decoder> invalid host, '%s'", $header);
            #    Ocean::Error::HTTPHandshakeError->throw(
            #        code => 400,
            #        type => q{Bad Request}, 
            #    );
            #    return;
            #}

            #if ( $env->{HTTP_SEC_WEBSOCKET_ORIGIN} eq $self->{_domain}) {
            #    $self->reset();
            #    debugf("<Stream> <Decoder> invalid host, '%s'", $header);
            #    Ocean::Error::HTTPHandshakeError->throw(
            #        code => 400,
            #        type => q{Bad Request}, 
            #    );
            #    return;
            #}

            # TODO better condition
            unless ( $env->{HTTP_CONNECTION} =~ /upgrade/i 
                &&   $env->{HTTP_UPGRADE}    =~ /websocket/i) {
                $self->reset();
                debugf("<Stream> <Decoder> invalid header 'Connection' or 'Upgrade', '%s'", $header);
                Ocean::Error::HTTPHandshakeError->throw(
                    code => 400,
                    type => q{Bad Request}, 
                );
                return;
            }

            my %header_params = ();

            my $protocol = $env->{HTTP_SEC_WEBSOCKET_PROTOCOL};
            # TODO protocol check
            $header_params{protocol} = $protocol if $protocol;

            unless ( exists $env->{HTTP_SEC_WEBSOCKET_KEY} ) {
                $self->reset();
                debugf("<Stream> <Decoder> invalid header, 'Sec-WebSocket-Key' '%s'", $header);
                Ocean::Error::HTTPHandshakeError->throw(
                    code => 400,
                    type => q{Bad Request}, 
                );
                return;
            }

            my $key = $env->{HTTP_SEC_WEBSOCKET_KEY};
            unless ($key) {
                debugf("<Stream> <Decoder> 'SEC-WEBSOCKET-KEY' not found");
                Ocean::Error::HTTPHandshakeError->throw(
                    code => 400,
                    type => q{Bad Request}, 
                );
                return;
            }

            my $accept = MIME::Base64::encode_base64(
                Digest::SHA1::sha1($key . GUID));
            chomp $accept;

            $header_params{accept} = $accept;

            debugf("<Stream> <Decoder> response for handshake KEY:%s ACCEPT:%s", $key, $accept);

            if ( exists $env->{HTTP_COOKIE} ) {
                debugf("<Stream> <Decoder> found cookie - %s", $env->{HTTP_COOKIE});
                my $cookie = Ocean::Util::HTTPBinding::parse_cookie($env->{HTTP_COOKIE});
                $header_params{cookie} = $cookie;
            }

            $self->{_on_handshake}->(\%header_params);

            debugf("<Stream> <Decoder> shakehand completed");

            $self->{_state} = STATE_HANDSHAKED;
            $self->_parse() if length $self->{_buffer} > 0;
        }
    } else {
        while (my $frame = $self->_parse_frame()) {

            my $op = $frame->[1] 
                || Ocean::Constants::WebSocketOpcode::CONTINUATION;

            if ( $op == Ocean::Constants::WebSocketOpcode::PING ) {
                $self->{_on_read_frame}->($op);
                next;
            }

            if ( $op == Ocean::Constants::WebSocketOpcode::CLOSE ) {
                $self->{_on_read_frame}->($op);
                last;
            }

            $self->{_message} .= $frame->[2];

            # Continuation
            next unless $op;

            my $message = $self->{_message};
            $self->{_message} = '';
            $self->{_on_read_frame}->($op, $message);
        }
    }
}

sub _parse_frame {
    my $self = shift;

    # Most of this code is borrowed from
    # Mojo::Transaction::WebSocket

    my $buffer = $self->{_buffer};

    # frame header requires 16bit(2byte)
    return unless length $buffer > 2;

    # get first 16bit
    my $head = substr $buffer, 0, 2;
    debugf("<Stream> <Decoder> websocket frame header <%s>", 
        unpack('B*', $head));

    # first bit is FIN flag
    my $fin = (vec($head, 0, 8) & 0b10000000) == 0b10000000 ? 1 : 0;

    # 4,5,6,7 bit represents Opcode
    my $op = vec($head, 0, 8) & 0b00001111;

    my $len = vec($head, 1, 8) & 0b01111111;

    my $hlen = 2;
    if ($len == 0) {
        debugf("<Stream> <Decoder> websocket frame header length is zero");
    }
    elsif ($len < 126) {
        debugf("<Stream> <Decoder> websocket frame is small");
    }
    elsif ($len == 126) {
        return unless length $buffer > 4;
        $hlen = 4;
        my $ext = substr $buffer, 2, 2;
        $len = unpack 'n', $ext;
        debugf("<Stream> <Decoder> websocket frame is extended (16bit) '%d'", $len);
    }
    elsif ($len == 127) {
        #return unless length $buffer > 8;
        #$head = substr $buffer, 0, 8, '';
        #$len = unpack 'N', substr($head, 4, 4);
        return unless length $buffer > 10;
        $hlen = 10;
        my $ext = substr $buffer, 2, 8;
        $len =
          $Config{ivsize} > 4
          ? unpack('Q>', $ext)
          : unpack('N', substr($ext, 4, 4));
        debugf("<Stream> <Decoder> websocket frame is extended (64bit) '%d'", $len);
    }

    #$self->finish and return if $len > $self->max_websocket_size;

    my $masked = vec($head, 1, 8) & 0b10000000;
    return if length $buffer < ($len + $hlen + $masked ? 4 : 0);
    substr $buffer, 0, $hlen, '';

    # Payload
    $len += 4 if $masked;
    return if length $buffer < $len;
    my $payload = $len ? substr($buffer, 0, $len, '') : '';

    # Unmask payload
    if ($masked) {
        debugf("<Stream> <Decoder> unmasking payload");
        $payload = Ocean::Util::WebSocket::xor_mask($payload, 
            substr($payload, 0, 4, ''));
    }

    $self->{_buffer} = $buffer;

    return [$fin, $op, $payload];
}

1;