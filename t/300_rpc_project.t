use strict;
use Test::More;
use t::Util qw(start_plackup jsonrpc_success jsonrpc_fail api_credential);
use Cirque::Util qw(random_ascii_string);
use Cirque::Client;

my $server = start_plackup "t/jsonrpc.psgi";
my $rpc_url = sprintf "http://127.0.0.1:%d/rpc", $server->port;

sub make_slug {
    my $slug;
    do {
        $slug = random_ascii_string 12;
    } while ( $slug =~ /^[^A-Za-z0-9]/ );
    return $slug;
}

# まだ全然ダミーだけど、とりあえずそれっぽいテスト
subtest 'basic' => sub {
    my $client = Cirque::Client->new( url => $rpc_url, api_credential() );

    my %args = (
        name => "Cirque",
        description => "dummy project",
    );
    $args{slug} = make_slug();
   

    my $response = $client->jsonrpc( "project.create" => \%args );

    # XXX TODO: check for failure
    if ( ! jsonrpc_success $response ) {
        return;
    }

    my $id = $response->{result}->{id};
    foreach my $cond ( ( { id => $id }, { slug => $args{slug} } ) ) {
        $response = $client->jsonrpc( "project.fetch" => $cond );
        if (! jsonrpc_success $response) {
            return;
        }

        is $response->{result}->{name}, $args{name};
        is $response->{result}->{slug}, $args{slug};
        is $response->{result}->{description}, $args{description};
    }

    $response = $client->jsonrpc( "project.update" => {
        id => $id,
        slug => "$args{slug}_boofoo",
    } );
    if (! jsonrpc_success $response ) {
        return;
    }

    $response = $client->jsonrpc( "project.fetch" => { id => $id } );
    if (! jsonrpc_success $response ) {
        return;
    }

    # XXX TODO: check for failure

    is $response->{result}->{name}, $args{name};
    is $response->{result}->{slug}, "$args{slug}_boofoo";
    is $response->{result}->{description}, $args{description};


    $response = $client->jsonrpc( "project.member.add" => {
        project_id => $id,
        account_id => 'azuma@bts.example.com',
        author => 'azuma@bts.example.com',
    } );
    if (! jsonrpc_success $response ) {
        return;
    }

    $response = $client->jsonrpc( "project.fetch" => { id => $id } );
    if (! jsonrpc_success $response ) {
        return;
    }
    isa_ok $response->{result}->{members}, 'ARRAY';
    is $response->{result}->{members}->[0], 'azuma@bts.example.com';

    $response = $client->jsonrpc( "project.member.delete" => {
        project_id => $id,
        account_id => 'azuma@bts.example.com',
        author => 'azuma@bts.example.com',
    } );
    if (! jsonrpc_success $response ) {
        return;
    }

    $response = $client->jsonrpc( "project.fetch" => { id => $id } );
    if (! jsonrpc_success $response ) {
        return;
    }
    isa_ok $response->{result}->{members}, 'ARRAY';
    is scalar @{$response->{result}->{members}}, 0;

    $response = $client->jsonrpc( "project.delete" => { id => $id } );
    if ( ! jsonrpc_success $response ) {
        return;
    }

    jsonrpc_fail $client->jsonrpc( "project.fetch" => { id => $id } );
};

subtest project_delete_with_issues => sub {
    my $client = Cirque::Client->new( url => $rpc_url, api_credential() );

    my $p1 = $client->jsonrpc('project.create' => {
        name => 'Project1',
        slug => make_slug(),
        description => 'hoge',
    } );
    if (! jsonrpc_success $p1 ) {
        return;
    }

    my $p2 = $client->jsonrpc('project.create' => {
        name => 'Project2',
        slug => make_slug(),
        description => 'hoge',
    } );
    if (! jsonrpc_success $p2 ) {
        return;
    }

    my $issue1 = $client->jsonrpc('issue.create' => {
        project_id => $p1->{result}->{id},
        title => 'foo',
        author    => 'hogefuga@bts.example.com',
        issue_type => 'bug',
        resolution => 'open',
        severity => 'major',
        description => 'oh,no!',
        assigned_to => 'poopoo@bts.example.com',
    } );
    if (! jsonrpc_success $issue1 ) {
        return;
    }

    my $issue2 = eval { $client->jsonrpc('issue.create' => {
        project_id => $p2->{result}->{id},
        title => 'bar',
        author    => 'hogefuga',
        issue_type => 'bug',
        resolution => 'open',
        severity => 'minor',
        description => 'oh,no!',
        assigned_to => 'poopoo',
    } ) };
    if (! jsonrpc_fail $issue2 ) {
        return;
    }

    my $res = $client->jsonrpc('project.delete' => { id => $p2->{result}->{id} } );
    if (! jsonrpc_success $res ) {
        return;
    }

    my $issuex = $client->jsonrpc('issue.fetch' => { id => $issue1->{result}->{id} });
    if (! jsonrpc_success $issuex ) {
        return;
    }
    is $issuex->{result}->{id}, $issue1->{result}->{id};
};

done_testing;
