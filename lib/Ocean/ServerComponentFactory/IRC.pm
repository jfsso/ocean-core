package Ocean::ServerComponentFactory::IRC;

use strict;
use warnings;

use parent 'Ocean::ServerComponentFactory';

use Ocean::StreamFactory::IRC;
use Ocean::StreamManager::Default;

sub create_stream_manager {
    my ($self, $config) = @_;
    return Ocean::StreamManager::Default->new;
}

sub create_stream_factory {
    my ($self, $config) = @_;
    return Ocean::StreamFactory::IRC->new;
}

1;
