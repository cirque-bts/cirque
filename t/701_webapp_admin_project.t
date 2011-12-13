use strict;
use Test::More;
use t::Util qw( start_each_servers browse browser_clear login_as_dummy_account );
use Cirque::Util qw( random_ascii_string );
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

$ENV{TEST_AUTH_TYPE} = 'Simple';

my $servers = start_each_servers();
browser_clear();

my $proj_name = 'proj'. random_ascii_string 12;
my $slug = lc $proj_name;

my ( $account, $password ) = login_as_dummy_account();
browse content_contains => $account;

subtest create => sub {
    browse content_unlike => qr/My Project/;
    browse follow_link_ok => { url => '/admin/project' };
    browse follow_link_ok => { url => '/admin/project/create' };
    browse submit_form_ok => {
        fields => {
            name => $proj_name,
            slug => $slug,
            enable_email => 0,
            description => 'Test Project',
            default_assignment => $account,
        },
    };
    browse get_ok => "/admin/project/$slug";
    browse content_contains => $proj_name;
};

subtest join => sub {
    browse submit_form_ok => {
        form_number => 1,
        fields => {
            account_id => $account,
        },
    };
    browse content_contains => sprintf( '<a class="project_member" href="/member/%s">%s</a>', $account, $account );
    browse content_contains => 'My Project';
};

subtest member_delete => sub {
    my $form_number = find_form_number {
       my $form = shift;
       return 1 if 
           $form->action->as_string =~ /project\/$slug\/member\/delete$/ && 
           $form->find_input( 'account_id' )->value eq $account
       ;
    };
    browse submit_form_ok => {
        form_number => $form_number,
    };
    my $member_link = sprintf( '<a class="project_member" href="/member/%s">%s</a>', $account, $account );
    browse content_unlike => qr/$member_link/;
    browse content_unlike => qr/My Project/;
};

subtest add_repository => sub {
    my $form_number = find_form_number {
        my $form = shift;
        return 1 if $form->action->as_string =~ "project/$slug/add_repo";
    };
    browse submit_form_ok => {
        form_number => $form_number,
        fields => {
            name => 'MyRepo1',
            url => 'https://github.com/rakudo/rakudo',
        },
    };
    browse content_contains => 'MyRepo1';
};

subtest milestone => sub {
    browse get_ok => "/admin/project/$slug";
    browse follow_link_ok => { url => "/admin/project/$slug/create/milestone" };
    browse content_contains => "Name";
    browse content_contains => "Due on";
    browse submit_form_ok => {
        fields => {
            name => 'next_milestone',
            due_on => '2011-12-01 00:00:00',
        },
    }, "success to creating new milestone";
    browse content_contains => 'next_milestone';
    browse content_contains => '2011-12-01 00:00:00';
    browse follow_link_ok => { text => 'next_milestone' };
    browse submit_form_ok => {
        fields => {
            name => 'oreore_milestone',
            due_on => '2011-12-31 00:00:00',
        },
    }, "success to fix new milestone";
    browse content_contains => 'oreore_milestone';
    browse content_contains => '2011-12-31 00:00:00';
};

subtest delete => sub {
    browse get_ok => "/admin/project/$slug/drop";
    browse content_unlike => qr/$proj_name/;
};

done_testing;
