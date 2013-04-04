package Ocean::StreamComponent::IO::Encoder::JSON::Default;

use strict;
use warnings;

use parent 'Ocean::StreamComponent::IO::Encoder::JSON';

use HTTP::Date;
use bytes ();
use Ocean::Constants::StreamErrorType;
use Ocean::Error;

sub send_http_handshake {
    my ($self, $params) = @_;

    Ocean::Error::ProtocolError->throw(
        type => Ocean::Constants::StreamErrorType::POLICY_VIOLATION,
    );
}

sub _build_http_header {
    my ($self, %params) = @_;

    my @lines = (
        sprintf("HTTP/1.1 %d %s", $params{code}, $params{type}),
        sprintf(q{Date: %s}, HTTP::Date::time2str(time())),
        "Content-Type: application/json",
        "Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0",
        "Pragma: no-cache",
        "Expires: -1",
        sprintf("Content-Length: %d", $params{length}),
        #"Connection: keep-alive",
    );

    my $header = join("\r\n", @lines);
    $header .= "\r\n\r\n";
    return $header;
}

sub send_packet {
    my ($self, $packet) = @_;

    my $json = $self->_encode_json($packet);

    # bytes::byte is deprecated?
    my $header = $self->_build_http_header(
        code   => 200,
        type   => q{OK},
        length => bytes::length($json)
    );

    $self->_write($header);
    $self->_write($json);
}

sub send_closing_http_handshake {
    my $self = shift;
    # do nothing
}


=pod

{ timeout: {
    retry: 0
} }

=cut

sub send_stream_error {
    my ($self, $type, $msg) = @_;
    if (   $type
        && $type eq Ocean::Constants::StreamErrorType::CONNECTION_TIMEOUT
        && $self->{_in_stream}) {
        $self->send_packet({
            timeout => {
                retry => 0,
            },
        });
    } else {
        my $obj = {
            type => 'stream',
        };
        if ($type) {
            $obj->{reason} = $type;
        }
        $obj->{message} = $msg if ($msg);

        my $json = $self->_encode_json({
            error => $obj,
        });

        # bytes::byte is deprecated?
        my $header = $self->_build_http_header(
            code   => 400,
            type   => q{Bad Request},
            length => bytes::length($json)
        );

        $self->_write($header);
        $self->_write($json);
    }
}

1;
