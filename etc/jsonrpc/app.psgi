use strict;
use lib ( "lib" );
use Cirque::Environment;
use Cirque::JSONRPC;

Cirque::JSONRPC->bootstrap()->to_app;
