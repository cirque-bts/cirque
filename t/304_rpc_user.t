use strict;
use Test::More;
use t::Util qw(start_plackup jsonrpc_success jsonrpc_fail api_credential);
use Cirque::Util qw(random_ascii_string);
use Cirque::Client;
use Data::Dumper;

my $server = start_plackup "t/jsonrpc.psgi";
my $rpc_url = sprintf "http://127.0.0.1:%d/rpc", $server->port;

my $client = Cirque::Client->new( url => $rpc_url, api_credential() );
eval {
    foreach my $account_id ( qw( azuma@bts.example.com foo@bar.baz ) ) {
        my $res = $client->jsonrpc( 'user.search' => {
            where => { account_id => $account_id }
        } );

        if ( ! $res->{error} ) {
            foreach my $account ( @{ $res->{result} || [] } ) {
                $client->jsonrpc( 'user.delete' => { id => $account->{id} } );
            }
        }
    }
};
diag $@;

subtest 'create_and_fetch' => sub {
    my $args = { 
        account_id => 'azuma@bts.example.com',
        name => 'azuma',
        icon => 'http://oreore.oreore/icon.png',
    };

    my $response = $client->jsonrpc( "user.create" => $args );
    if ( ! jsonrpc_success $response ) {
        return;
    }
    my $user_id = $response->{result}->{id};

    $response = $client->jsonrpc( "user.fetch" => { id => $user_id } );
    if ( ! jsonrpc_success $response ) {
        return;
    }

    my $row = $response->{result};
    for my $key ( qw/ id auth.api_key auth.api_secret / ) { 
        delete $args->{$key};
        delete $row->{$key};
    }

    is ref $row, 'HASH', "row is hashref";
    is_deeply $row, $args, "rows->[0] equal args, got \n".Dumper( $row );
};

subtest 'search' => sub {
    my $args = {
        account_id => 'foo@bar.baz',
        name => 'hoge',
        icon => 'hogehoge.jpg',
    };
    my $response = $client->jsonrpc( "user.create" => $args );
    if ( ! jsonrpc_success $response ) {
        return;
    }
    
    $response = $client->jsonrpc( 'user.search' => { where => { account_id => 'foo@bar.baz' } } );
    my $rows = $response->{result};

    is ref $rows, 'ARRAY';
    is scalar @$rows, 1;    

    for my $key ( qw/ id auth.api_secret auth.api_key / ) {
        delete $rows->[0]->{"$key"};
        delete $args->{"$key"};
    }
    is_deeply $rows->[0], $args;
};

done_testing;
