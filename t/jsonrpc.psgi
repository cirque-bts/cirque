use strict;
use Cirque::JSONRPC;

Cirque::JSONRPC->bootstrap(
    config => "t/config.pl",
)->to_app;
