use strict;
use Test::More;
use t::Util qw( create_ctxt start_each_servers browse browser_clear login_as_dummy_account );
use Cirque::Util qw( random_ascii_string );
use File::Spec;
use Encode;

$ENV{TEST_AUTH_TYPE} = 'Simple';
my $servers = start_each_servers();

my $ctxt = create_ctxt;
my $rpc = $ctxt->get( 'API::RPC' );
flush_projects( $rpc );

sub flush_projects {
    my $rpc = shift;
    my $projects = $rpc->project_projects;
    for my $p ( @$projects ) {
        $rpc->project_delete( { id => $p->{id} } );
    }
}

sub create_dummy_project {
    my ( $account ) = @_;
    my $proj_name = 'proj'. random_ascii_string 12;
    my $slug = lc $proj_name;
    browse get => '/admin/project/create';
    browse submit_form => (
        fields => {
            name => $proj_name,
            slug => $slug,
            enable_email => 0,
            description => 'Test Project',
            default_assignment => $account,
        },
    );
    return {
        name => $proj_name,
        slug => $slug,
    };
}

sub delete_project{
    my $slug = shift;
    browse get => "/admin/project/$slug/drop";
};

subtest noprojects_nologin => sub {
    browser_clear();
    browse get_ok => '/project/list';
    browse content_unlike => qr/Create New Project/;
};

subtest noprojects_login => sub {
    browser_clear();
    my ( $account, $password ) = login_as_dummy_account();
    browse get_ok => '/project/list';
    content_contains => 'Create New Project';
};

browser_clear();
my ( $account, $password ) = login_as_dummy_account();
my $proj = create_dummy_project( $account );

subtest projects_nologin => sub {
    browser_clear();
    browse get_ok => '/project/list';
    browse content_contains => $proj->{name};
    browse content_unlike => qr/JOIN/;
    browse content_unlike => qr/REPORT/;
};

subtest projects_login => sub {
    browser_clear();
    my ( $account, $password ) = login_as_dummy_account();
    browse get_ok => '/project/list';
    browse content_contains => $proj->{name};
    browse content_contains => 'JOIN';
    browse content_contains => 'REPORT';
};

delete_project( $proj->{slug} );

done_testing;
