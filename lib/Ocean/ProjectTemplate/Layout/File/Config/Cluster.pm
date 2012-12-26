package Ocean::ProjectTemplate::Layout::File::Config::Cluster;

use strict;
use warnings;

use parent 'Ocean::ProjectTemplate::Layout::File';

sub template     { do { local $/; <DATA> } }
sub default_name { 'xmpp.yml'              }

1;
__DATA__
---
server:
  type: xmpp
  domain: xmpp.example.org
  host: 192.168.0.1
  port: 5222
  backlog: 1024
  max_connection: 100000
  timeout: 300
  max_read_buffer: 10000
  report_interval: 60
  use_stanza_counter: yes
  stanza_counter_expiration: 60
  max_stanza_count: 1000
  pid_file: __path_to(<: $layout.relative_path_for('run_dir') :>/xmpp.pid)__
  context_class: <: $context.get('context_class') :>

log:
  type: print
  formatter: color
  level: info
  show_packets: yes
  filepath: __path_to(<: $layout.relative_path_for('log_dir') :>/xmpp.log)__

sasl:
  mechanisms:
    - PLAIN
#   - CRAM-MD5
#   - DIGEST-MD5
#   - X-OAUTH2

#tls:
#  cert_file: __path_to(<: $layout.relative_path_for('cert_pem') :>)__
#  key_file: __path_to(<: $layout.relative_path_for('cert_key') :>)__
#  cipher_list: ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP:+eNULL

event_handler:
  node:       <: $context.get('handler_class') :>::Node
  authen:     <: $context.get('handler_class') :>::Authen
  connection: <: $context.get('handler_class') :>::Connection
  message:    <: $context.get('handler_class') :>::Message
  people:     <: $context.get('handler_class') :>::People
  room:       <: $context.get('handler_class') :>::Room
  p2p:        <: $context.get('handler_class') :>::P2P

handler:
  node_id: node01
  serializer: json
  router: __path_to(<: $layout.relative_path_for('config_dir') :>/router.pl)__
  fetcher:
    class: Ocean::Cluster::Frontend::Fetcher::Gearman
    config:
      inbox_host: 127.0.0.1
      inbox_port: 7001
  dispatcher:
    class: Ocean::Cluster::Frontend::Dispatcher::Gearman
    config:
        servers:
            - 192.168.0.2:7001
            - 192.168.0.2:7002
            - 192.168.0.2:7003
            - 192.168.0.2:7004

