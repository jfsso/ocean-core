package Ocean::HTTPBinding::StreamFactory::Default;

use strict;
use warnings;

use parent 'Ocean::StreamFactory';

use Ocean::Stream;
use Ocean::StreamComponent::IO;
use Ocean::StreamComponent::IO::Decoder::JSON;
use Ocean::StreamComponent::IO::Encoder::JSON::Default;

sub create_stream {
    my ($self, $client_id, $client_socket) = @_;
    return Ocean::Stream->new(
        id => $client_id,
        io => Ocean::StreamComponent::IO->new(
            decoder => Ocean::StreamComponent::IO::Decoder::JSON->new,
            encoder => Ocean::StreamComponent::IO::Encoder::JSON::Default->new,
            socket  => $client_socket,
        ),
        initial_protocol => Ocean::Constants::ProtocolPhase::HTTP_SESSION_HANDSHAKE,
    );
}

1;
