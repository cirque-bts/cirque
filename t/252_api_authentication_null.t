use Test::More;
use strict;

$ENV{TEST_AUTH_TYPE} = 'Null';

use t::Util qw(create_ctxt start_plackup);

my $rpc_srv = start_plackup "t/jsonrpc.psgi";
$ENV{TEST_RPC_PORT} = $rpc_srv->port;

my $ctxt = create_ctxt();

my $api = $ctxt->get( 'API::Authentication' );
isa_ok $api, 'Cirque::API::Authentication::Null';

subtest basic => sub {
    my $res = eval { $api->authenticate( { email => 'tonkichi@higashi.test', password => 'foobar' } ) };
    ok !$@, "authenticate is expected no error. but got : $@";
    ok $res, "authenticate is expected succeed. but got : $@";
 
    $res = eval { $api->authenticate( { email => 'tonkichi@higashi.test', password => '1111' } ) };
    ok !$@, "authenticate is expected no error. but got : $@";
    ok $res, "authenticate is expected succeed. but got : $@";
};

done_testing;
