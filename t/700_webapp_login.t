use strict;
use Test::More;
use t::Util qw( start_each_servers browse browser_clear gen_dummy_account login_credentials );
use Encode;

$ENV{TEST_AUTH_TYPE} = 'Simple';

my $servers = start_each_servers();

isa_ok $servers, 'HASH';

for my $key ( keys %$servers ) {
    my $server = $servers->{$key};
    isa_ok $server, 'Test::TCP';
    ok $server->port > 0;
}

my ( $account, $password ) = login_credentials();
browser_clear();

subtest toppage => sub {
    browse 'get_ok';
    browse content_contains => 'Email';
    browse content_contains => 'Password';
};

subtest login_failure => sub {
    my @credentials = gen_dummy_account();
    browse submit_form_ok => {
        fields => { 
            email => $credentials[0],
            password => $credentials[1],
        }
    }, 'logging in was expected failure';
    browse content_contains => 'Email';
    browse content_contains => 'Password';
};

subtest login_success => sub {
    browse get_ok => '/login';
    browse content_contains => 'Email';
    browse content_contains => 'Password';
    browse submit_form_ok => {
        fields => { 
            email => $account,
            password => $password,
        }
    }, 'logging in was expected success';
    browse content_contains => 'Assigned Issues';
    browse content_contains => $account;
};

subtest logout => sub {
    my ( $link ) = browse find_link => ( url => '/logout' );
    ok $link, 'Link for logout is there';
    browse follow_link_ok => { url => '/logout' };
    browse content_contains => 'Login';
    browse content_contains => 'Email';
    browse content_contains => 'Password';
};

done_testing;
