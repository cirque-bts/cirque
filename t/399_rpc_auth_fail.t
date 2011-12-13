use strict;
use utf8;
use Test::More;
use t::Util qw(create_ctxt start_plackup jsonrpc_success jsonrpc_fail invalid_api_credential );
use Cirque::Client;

my $server = start_plackup "t/jsonrpc.psgi";
my $rpc_url = sprintf "http://127.0.0.1:%d/rpc", $server->port;
my $ctxt = create_ctxt();

subtest 'basic' => sub {
    my $client = Cirque::Client->new( url => $rpc_url, invalid_api_credential() );

    my $response = $client->jsonrpc( "project.projects" => {} );

    if (! jsonrpc_fail $response) {
        return;
    }
    like $response->{error}->{message}, qr/^Authorization Failure/;

};

done_testing;
