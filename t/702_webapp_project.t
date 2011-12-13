use strict;
use Test::More;
use t::Util qw( start_each_servers browse browser_clear login_as_dummy_account );
use Cirque::Util qw( random_ascii_string );
use File::Spec;
use Encode;

sub find_form_number (&) {
    my $rule = shift;
    my @forms = browse 'forms';
    my $i = 0;
    for my $form ( @forms ) { 
        $i++;
        last if $rule->( $form );
    }
    return $i;
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

$ENV{TEST_AUTH_TYPE} = 'Simple';

my $servers = start_each_servers();
browser_clear();

my ( $account, $password ) = login_as_dummy_account();
my $proj = create_dummy_project( $account );

subtest project_page => sub {
    browse get_ok => sprintf "/project/%s",$proj->{slug};
    browse content_contains => $proj->{name};
    browse content_contains => 'Test Project';
    browse content_contains => "Not defined";
    browse content_contains => "Progress";
    browse content_contains => sprintf "Issues - %s", $proj->{name};
    browse content_contains => 'History';
    browse content_contains => 'Empty';
};

subtest create_issue => sub {
    browse get_ok => sprintf "/project/%s",$proj->{slug};
    browse follow_link_ok => { url => sprintf "/project/%s/issue/report", $proj->{slug} };
    browse submit_form_ok => {
        fields => {
            title => 'Test Issue',
            issue_type => 'improvement',
            assignment => $account,
            severity => 'critical',
            description => 'This is a test!',
        },
    }, 'success to creating an issue';
    browse content_contains => 'Test Issue';
    browse content_contains => $proj->{name};
    browse content_contains => 'critical';
    browse content_contains => 'open';
    browse content_contains => 'This is a test!';
};

subtest work_for_issue => sub {
    browse submit_form_ok => {
        form_id => 'editdetails',
        fields => {
            resolution => 'in-progress',
            comment => 'began to work!',
        },
    }, 'success to changing severity';
    browse content_contains => 'Test Issue';
    browse content_contains => $proj->{name};
    browse content_contains => 'critical';
    browse content_contains => 'in-progress';
    browse content_contains => 'This is a test!';
    browse content_contains => 'began to work!';
};

subtest add_comment => sub {
    browse submit_form_ok => {
        form_id => 'comment_form',
        fields => {
            body => 'コメントのテストです！',
        },
    }, 'success to comment';
    browse content_contains => 'コメントのテストです！';
};

subtest edit_comment => sub {
    my $form_number = find_form_number {
        my $form = shift;
        my $body = $form->find_input( 'body' );
        return unless $body;
        $body->value eq 'コメントのテストです！';
    };
    browse submit_form_ok => {
        form_number => $form_number, 
        fields => {
            body => 'コメントを書き換えました！',
        },
    }, 'success to editing a comment';
    browse content_unlike => qr/コメントのテストです！/;
    browse content_contains => 'コメントを書き換えました！';
};

subtest attachment => sub {
    my ( $content ) = browse 'content';
    my ( $issue_id ) = $content =~ qr/<h2 class=\"issue_id\">#(\d+?) /;
    my $form_number = find_form_number {
        my $form = shift;
        my $match = sprintf "/issue/%d/attach", $issue_id;
        return $form->action->as_string =~ /$match$/;
    };
    browse submit_form_ok => {
        form_number => $form_number,
        fields => {
            file => File::Spec->catfile( qw/ t data upload_test.png / ),
        },
    }, 'success to attach';
    browse content_contains => 'upload_test.png';
    browse follow_link_ok => { text => '[remove this file]' };
    browse content_contains => "removed file 't/data/upload_test.png'";
};

delete_project( $proj->{slug} );

done_testing;
