use Test::More;
use strict;

$ENV{TEST_AUTH_TYPE} = 'Simple';

use t::Util qw(create_ctxt start_plackup login_credentials);
use Try::Tiny;

my $rpc_srv = start_plackup "t/jsonrpc.psgi";
$ENV{TEST_RPC_PORT} = $rpc_srv->port;

subtest basic => sub {
    my $ctxt = create_ctxt();

    my $api = $ctxt->get( 'API::Authentication' );
    isa_ok $api, 'Cirque::API::Authentication::Simple';

    my ( $account, $password ) = login_credentials();

    my $res;
    my $err;
    try {
        $res = $api->authenticate( { 
            email => $account,
            password => $password,
        } ); 
    } catch {
        fail( "authenticate is expected no error. but got : $_" );
    };
    ok $res, "authenticate is expected succeed.";
};

done_testing;
