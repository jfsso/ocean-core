package Ocean::StreamComponent::IO::Decoder::IRC;

use strict;
use warnings;

use parent 'Ocean::StreamComponent::IO::Decoder';

use Try::Tiny;
use JSON::XS;
use Log::Minimal;

use Ocean::Error;
use Ocean::Constants::EventType;
use Ocean::Constants::StanzaErrorType;
use Ocean::Constants::StanzaErrorCondition;
use Ocean::Constants::StreamErrorType;
use Ocean::Constants::WebSocketOpcode;

use Ocean::IRC::StanzaClassifier;

use constant {
    DELEGATE => 0,
};

sub new {
    my ($class, %args) = @_;
    my $self = bless [
        undef,  # DELEGATE
    ], $class;

    return $self;
}

sub initialize {
    my $self = shift;
    # do nothing
}

sub set_delegate {
    my ($self, $delegate) = @_;
    $self->[DELEGATE] = $delegate;
}

sub release_delegate {
    my $self = shift;
    $self->[DELEGATE] = undef
        if $self->[DELEGATE];
}

sub _handle_command {
    my ($self, $command, $arguments);

    my $event_type = Ocean::IRC::StanzaClassifier->classify($command, $arguments);
    return unless $event_type;

    $self->_dispatch_event($event_type, $command, $arguments);
}

sub feed {
    my ($self, $data) = @_;
    my ($command, $arguments) = split / /, $data, 2;
    $self->_handle_command($command, $arguments) if $command;
}

sub release {
    my $self = shift;
    $self->release_delegate();
}

1;
