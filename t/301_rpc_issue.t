use strict;
use utf8;
use Test::More;
use t::Util qw(
    create_ctxt
    create_anon_repo
    create_anon_project
    get_repo
    get_bare_repo
    start_plackup
    jsonrpc_success
    jsonrpc_fail
    api_credential
);
use Cirque::Client;
use Cirque::Util qw(random_ascii_string);
use URI;

my $server = start_plackup "t/jsonrpc.psgi";
my $rpc_url = sprintf "http://127.0.0.1:%d/rpc", $server->port;
my $ctxt = create_ctxt();

my $client = Cirque::Client->new( url => $rpc_url, api_credential() );

my $cirque_repo = get_repo;
my $repo = $cirque_repo || create_anon_repo;

my $proj = create_anon_project $ctxt, {
    repos => [
        { url => "http://dummy/bar.git", name => 'repo2' },
        { url => "http://dummy/foo.git", name => 'repo0' },
        { url => $repo, name => 'repo1', link_pattern => 'http://git.example.com/%s/commit/%%commit' },
    ]
};

END {
    eval {
        $ctxt->get('API::Project')->delete({ id => $proj->id } );
    };
}


my %args = (
    project_id => $proj->id,
    author    => 'lestrrat@bts.example.com',
    title => 'てすと',
    issue_type => 'bug',
    resolution => 'open',
    severity => 'major',
    description => 'XXX FIXME XXX',
    assigned_to => 'lestrrat@bts.example.com',
    version => '1.00',
    cc => 'azuma',
);

subtest 'basic' => sub {
    my $response = $client->jsonrpc( "issue.create" => \%args );
    if (! jsonrpc_success $response) {
        return;
    }

    my $id = $response->{result}->{id};
    $response = $client->jsonrpc( "issue.fetch" => { id => $id } );
    if (! jsonrpc_success $response) {
        return;
    }

    is $response->{result}->{title}, $args{title};
    # XXX add more

    $response = $client->jsonrpc( "issue.update" => {
        id => $id,
        author => 'lestrrat@bts.example.com',
        title => "$args{title}.boofoo",
    } );
    if (! jsonrpc_success $response ) {
        return;
    }

    $response = $client->jsonrpc( "issue.fetch" => { id => $id } );
    if (! jsonrpc_success $response ) {
        return;
    }
    is $response->{result}->{title}, "$args{title}.boofoo";
    # XXX add more


    my $new_cc = 'azuma@bts.example.com, daisukem@bts.example.com';
    $response = $client->jsonrpc( "issue.update" => {
        id => $id,
        author => 'azuma@bts.example.com',
        cc => $new_cc,
    } );
    if (! jsonrpc_success $response ) {
        return;
    }

    $response = $client->jsonrpc( "issue.fetch" => { id => $id } );
    if (! jsonrpc_success $response ) {
        return;
    }
    is $response->{result}->{cc}, 'azuma@bts.example.com, daisukem@bts.example.com';

    if (! jsonrpc_success $client->jsonrpc( "issue.delete" => { id => $id } )) {
        return;
    }

    jsonrpc_fail $client->jsonrpc( "issue.fetch" => { id => $id } );
};

subtest 'illegal_milestone_id' => sub {
    $args{milestone_id} = '0';
    my $response = $client->jsonrpc( "issue.create" => \%args );
    if (! jsonrpc_success $response) {
        return;
    }

    my $id = $response->{result}->{id};
    $response = $client->jsonrpc( "issue.fetch" => { id => $id } );
    if (! jsonrpc_success $response) {
        return;
    }

    my $milestone_res = $client->jsonrpc( "milestone.fetch" => { 
        id => $response->{result}->{milestone_id},
    } );
    if (! jsonrpc_success $milestone_res) {
        return;
    }
    is $milestone_res->{result}->{name}, 'Not defined';

    $args{milestone_id} = 'DummyBuggy';
    $response = $client->jsonrpc( "issue.create" => \%args );
    if (! jsonrpc_fail $response) {
        return;
    }
};

subtest 'preview rendering' => sub {
    my $i;
    my $x = 0;

    my ($repo) = grep { $x++; if( $_->link_pattern ) { $i = $x; 1 } else { 0 } }
        @{ $ctxt->get('API::Repository')->load_by_project( $proj->id ) };

    my $url = URI->new($repo->link_pattern);
    $url->path('/');
    my $furl = Furl::HTTP->new(timeout => 1);
    my @res = $furl->head( $url );
    SKIP: {
        if ($res[1] ne 200) {
            skip "$url is not available", 1;
        }

        # get current HEAD
        my ($sha1) = `git log -n 1 --pretty='%H'`;
        chomp $sha1;

        my $bare_repo = get_bare_repo( $repo->url );
        my ($remote_sha1) = $bare_repo->( qw( log -n 1 --pretty='%H' ) );

        unless ( $sha1 eq $remote_sha1 ) {
            skip "$sha1 is not exists in origin", 1;
        }

        my $response = $client->jsonrpc("issue.preview" => {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for preview',
            issue_type => 'improvement',
            description => <<EOM
git#$sha1 git#$sha1
EOM
        });

        if (! jsonrpc_success $response) {
            diag explain $response;
            return;
        }

        if ( ! like $response->{result}->{description}, qr/git#$i#$sha1 git#$i#$sha1/, "properly formatted with git repo ID" ) {
            diag explain $response;
        }
    }
};


done_testing;
