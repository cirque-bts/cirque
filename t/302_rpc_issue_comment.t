use strict;
use Test::More;
use t::Util qw(
    create_ctxt
    create_anon_project
    create_anon_repo
    get_repo
    get_bare_repo
    start_plackup
    jsonrpc_success
    jsonrpc_fail
    api_credential
);
use Cirque::Util qw(random_utf8_string random_ascii_string);
use Cirque::Client;
use Encode;
use URI;

my $server = start_plackup "t/jsonrpc.psgi";
my $rpc_url = sprintf "http://127.0.0.1:%d/rpc", $server->port;
my $ctxt = create_ctxt();

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

my $client = Cirque::Client->new( url => $rpc_url, api_credential() );

subtest 'basic' => sub {
    my %args = (
        project_id => $proj->id,
        author    => 'lestrrat@bts.example.com',
        title => 'XXX FIXME XXX',
        issue_type => 'bug',
        resolution => 'open',
        severity => 'major',
        description => 'XXX FIXME XXX',
        assigned_to => 'lestrrat@bts.example.com',
        version => '1.00',
        cc => 'azuma@bts.example.com',
    );

    my $response = $client->jsonrpc( "issue.create" => \%args );
    if (! jsonrpc_success $response ) {
        return;
    }

    my $issue_id = $response->{result}->{id};
    my %comment_args = (
        issue_id => $issue_id,
        author   => 'lestrrat@bts.example.com',
        body     => encode_utf8( random_utf8_string 256 )
    );
    $response = $client->jsonrpc( "issue.comment.create" => {
        %comment_args,
    } );
    if (! jsonrpc_success $response) {
        return;
    }

    my $comment_id = $response->{result}->{id};

    $response = $client->jsonrpc( "issue.comment.fetch" => {
        id => $comment_id
    } );
    if (! jsonrpc_success $response) {
        return;
    }
    my $comment = $response->{result};
    my $created_on  = delete $comment->{created_on};
    my $modified_on = delete $comment->{modified_on};
    my $project_id  = delete $comment->{project_id};
    is_deeply $comment, { %comment_args, id => $comment_id };


    sleep 2;
    my $rand_str = encode_utf8( random_utf8_string 64 );
    $response = $client->jsonrpc( "issue.comment.update" => {
        id     => $comment_id,
        author => 'lestrrat@bts.example.com',
        body   => $rand_str,
    } );
    if (! jsonrpc_success $response) {
        return;
    }
    is_deeply $comment, { %comment_args, id => $comment_id };
    
    $response = $client->jsonrpc( "issue.comment.fetch" => {
        id => $comment_id
    } );
    if (! jsonrpc_success $response) {
        return;
    }
    $comment = $response->{result};
    is $comment->{created_on}, $created_on;
    isnt $comment->{modified_on}, $modified_on;
    is $comment->{body}, $rand_str;


    # XXX need more tests

    $response = $client->jsonrpc( "issue.delete" => {
        id => $issue_id
    });
    if (! jsonrpc_success $response) {
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

        # create reference issue
        my %args = (
            project_id => $proj->id,
            author    => 'lestrrat@bts.example.com',
            title => 'XXX FIXME XXX',
            issue_type => 'bug',
            resolution => 'open',
            severity => 'major',
            description => 'XXX FIXME XXX',
            assigned_to => 'lestrrat@bts.example.com',
            version => '1.00',
            cc => 'azuma@bts.example.com',
        );

        my $response = $client->jsonrpc( "issue.create" => \%args );
        if (! jsonrpc_success $response ) {
            return;
        }

        my $issue_id = $response->{result}->{id};

        # get current HEAD
        my ($sha1) = `git log -n 1 --pretty='%H'`;
        chomp $sha1;

        # get current origin HEAD
        my $bare_repo = get_bare_repo( $repo->url );
        my ($remote_sha1) = $bare_repo->( qw( log -n 1 --pretty='%H' ) );

        unless ( $sha1 eq $remote_sha1 ) {
            skip "$sha1 is not exists in origin", 1;
        }

        my $response = $client->jsonrpc("issue_comment.preview" => {
            issue_id   => $issue_id,
            project_id => $proj->id,
            author     => "foobar",
            created_on => POSIX::strftime( '%Y-%m-%d %H:%M:%S', localtime() ),
            body       => <<EOM
git#$sha1 git#$sha1
EOM
        });

        if (! jsonrpc_success $response) {
            diag explain $response;
            return;
        }

        if ( ! like $response->{result}->{body}, qr/git#$i#$sha1 git#$i#$sha1/, "properly formatted with git repo ID" ) {
            diag explain $response;
        }
    }
};


done_testing;
