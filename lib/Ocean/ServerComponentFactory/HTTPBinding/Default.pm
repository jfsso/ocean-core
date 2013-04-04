package Ocean::ServerComponentFactory::HTTPBinding::Default;

use strict;
use warnings;

use parent 'Ocean::ServerComponentFactory';

use Ocean::HTTPBinding::StreamFactory::Default;
use Ocean::HTTPBinding::StreamManager;

sub create_stream_manager {
    my ($self, $config) = @_;
    return Ocean::HTTPBinding::StreamManager->new;
}

sub create_stream_factory {
    my ($self, $config) = @_;
    return Ocean::HTTPBinding::StreamFactory::Default->new;
}

1;
