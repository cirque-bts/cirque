use strict;
use Cirque::Web;

Cirque::Web->bootstrap(
    config => 't/config.pl',
)->to_app;
