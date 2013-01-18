package Ocean::StreamComponent::IO::Encoder::IRC;

use strict;
use warnings;

use parent 'Ocean::StreamComponent::IO::Encoder';

use Log::Minimal;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        _on_write  => undef, 
        _in_stream => 0,
    }, $class;
    return $self;
}

sub on_write {
    my ($self, $callback) = @_;
    $self->{_on_write} = $callback;
}

sub initialize {
    my $self = shift;
}

sub _write {
    my ($self, $packet) = @_;
    $self->{_on_write}->($packet);
}

sub send_http_handshake {
    my ($self, $handshake) = @_;
    # do nothing
}

sub send_http_handshake_error {
    my ($self, $code, $type) = @_;
    # do nothing
}

sub send_closing_http_handshake {
    my ($self) = @_;
    # do nothing
}

sub send_initial_stream {
    my ($self, $id, $domain) = @_;
    # template method
    # TODO
}

sub send_end_of_stream {
    my $self = shift;
    # template method
    # TODO
    # ERROR :Closing Link: MyNickname[MyUsername@client.example.com] (I Quit)
}

sub send_stream_error {
    my ($self, $type, $msg) = @_;
    # template method
    # TODO
    # ERROR :Closing Link: MyNickname[MyUsername@client.example.com] (I Quit)
}

sub send_stream_features {
    my ($self, $features) = @_;
    # template method
}

sub send_sasl_challenge {
    my ($self, $challenge) = @_;
    # template method
}

sub send_sasl_success {
    my ($self) = @_;
    # template method
}

sub send_sasl_failure {
    my ($self, $type) = @_;
    # template method
}

sub send_sasl_abort {
    my ($self, $type) = @_;
    # template method
}

sub send_tls_proceed {
    my ($self, $type) = @_;
    # template method
}

sub send_tls_failure {
    my ($self, $type) = @_;
    # template method
}

sub send_presence {
    my ($self, $presence) = @_;
    # template method
    # TODO
}

sub send_unavailable_presence {
    my ($self, $from, $to) = @_;
    # template method
    # TODO
}

sub send_message {
    my ($self, $message) = @_;
    # template method
    # TODO
}

sub send_room_invitation {
    my ($self, $invitation) = @_;
    # template method
    # TODO
}

sub send_room_invitation_decline {
    my ($self, $invitation) = @_;
    # template method
}

sub send_pubsub_event {
    my ($self, $event) = @_;
    # template method
}

sub send_message_error {
    my ($self, $error) = @_;
    # template method
    # TODO
}

sub send_presence_error {
    my ($self, $error) = @_;
    # template method
}

sub send_iq_error {
    my ($self, $error) = @_;
    # template method
}

sub send_bind_result {
    my ($self, $id, $domain, $result) = @_;
    # template method
}

sub send_session_result {
    my ($self, $id, $domain) = @_;
    # template method
}

sub send_roster_result {
    my ($self, $id, $domain, $to, $roster) = @_;
    # template method
}

sub send_roster_push {
    my ($self, $id, $domain, $to, $item) = @_;
    # template method
}

sub send_pong {
    my ($self, $id, $domain, $to) = @_;
    # template method
}

=pod

IRC whois <=> vcard

=cut
sub send_vcard {
    my ($self, $id, $to, $vcard) = @_;
    # template method
    # TODO
}

sub send_iq_toward_user {
    my ($self, $id, $to, $query) = @_;
    # template method
}

sub send_jingle_info {
    my ($self, $id, $to, $info) = @_;
    # template method
}

sub send_server_disco_info {
    my $self = shift;
    # template method
    # TODO
}

sub send_server_disco_items {
    my $self = shift;
    # template method
    # TODO
}

sub release {
    my $self = shift;
    # template method
}

1;
