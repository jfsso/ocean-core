package Ocean::IRC::StanzaClassifier;

use strict;
use warnings;

use Ocean::Constants::EventType;

sub classify {
    my ($self, $command, $arguments) = @_;

    if ($command eq 'NICK') {
        # ignore: use database
    } elsif ($command eq 'USER') {
        # ignore: use database
    } elsif ($command eq 'PASS') {
        return Ocean::Constants::EventType::IRC_AUTH_REQUEST;
    } elsif ($command eq 'PRIVMSG' || $command eq 'NOTICE') {
        if ($arguments =~ /^#/) {
            return Ocean::Constants::EventType::SEND_ROOM_MESSAGE;
        } else {
            return Ocean::Constants::EventType::SEND_MESSAGE;
        }
    } elsif ($command eq 'WHOIS') {
        return Ocean::Constants::EventType::VCARD_REQUEST;
    } elsif ($command eq 'JOIN') {
        return Ocean::Constants::EventType::ROOM_PRESENCE;
    } elsif ($command eq 'PART') {
        return Ocean::Constants::EventType::LEAVE_ROOM_PRESENCE;
    } elsif ($command eq 'INVITE') {
        return Ocean::Constants::EventType::ROOM_INVITATION;
    } elsif ($command eq 'NAMES') {
        return Ocean::Constants::EventType::ROOM_MEMBERS_LIST_REQUEST;
    } elsif ($command eq 'AWAY') {
        return Ocean::Constants::EventType::BROADCAST_PRESENCE;
    } elsif ($command eq 'QUIT') {
        return Ocean::Constants::EventType::BROADCAST_UNAVAILABLE_PRESENCE;
    } elsif ($command eq 'PONG') {
        # TODO
    }
    return;
}

1;
