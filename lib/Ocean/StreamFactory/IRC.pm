package Ocean::StreamFactory::IRC;

use strict;
use warnings;

use parent 'Ocean::StreamFactory';

use Ocean::Stream;
use Ocean::StreamComponent::IO;
use Ocean::StreamComponent::IO::Decoder::IRC;
use Ocean::StreamComponent::IO::Encoder::IRC;

sub create_stream {
    my ($self, $client_id, $client_socket) = @_;
    return Ocean::Stream->new(
        id => $client_id,
        io => Ocean::StreamComponent::IO->new(
            decoder => Ocean::StreamComponent::IO::IRC::Default->new,
            encoder => Ocean::StreamComponent::IO::IRC::Default->new,
            socket  => $client_socket,
        ),
    );
}

1;
