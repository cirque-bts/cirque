package t::lib::App::Prove::Plugin::StartMemcached;
use strict;
use Test::More;
use Test::TCP;

our $MEMCACHED;

sub load {
    diag "Checking for explicit TEST_MEMCACHED_SERVERS";
    # do we have an explicit memcached somewhere?
    if (my $servers = $ENV{TEST_MEMCACHED_SERVERS}) {
        return;
    }

    $MEMCACHED = Test::TCP->new(code => sub {
        my $port = shift;
        exec "memcached -l 127.0.0.1 -p $port";
    });

    $ENV{TEST_MEMCACHED_SERVERS} = '127.0.0.1:' . $MEMCACHED->port;
}

1;