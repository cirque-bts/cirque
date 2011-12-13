use Test::More;
use strict;

use File::Spec;
use Cirque::Util qw(random_ascii_string);
use Cirque::Context;
use t::Util qw(assert_email_count create_ctxt get_bare_repo);
use Cirque::API::Issue;
use Data::Dumper;
use Email::Send::Test;
use Time::Piece;
use URI;

my $ctxt = create_ctxt;

my ($repo) = (split /=/, `git config --list | grep remote.origin.url`)[1];
if (! $repo) {
    $repo = "http://foobar.example.com/member_test.git";
}
chomp $repo;

my $proj = $ctxt->get('API::Project')->create( {
    name => random_ascii_string 12,
    slug => random_ascii_string 10,
    repos => [
        { url => "http://dummy/bar.git", name => 'repo2' },
        { url => "http://dummy/foo.git", name => 'repo0' },
        { url => $repo, name => 'repo1', link_pattern => 'http://git.example.com/%s/commit/%%commit' },
    ]
} );

my $api = $ctxt->get('API::Issue');
isa_ok $api, "Cirque::API::Issue";

subtest "create" => sub {
    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 7;
    };

    my @pattern = (
        { args      => undef,
          exception => qr/Could not find associated milestones/,
          isa       => undef,
          name      => 'undefined args',
        },
        { args      => {},
          exception => qr/Could not find associated milestones/,
          isa       => undef,
          name      => 'empty args',
        },
        { args      => { project_id => 'IT IS NOT REALLY EXISTS',
                       },
          exception => qr/Could not find associated milestones/,
          isa       => undef,
          name      => 'dummy project_id',
        },
        { args      => { project_id => $proj->id,
                       },
          exception => qr/Field \'author\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'project_id only',
        },
        { args      => { project_id => $proj->id,
                         author => undef,
                       },
          exception => qr/Field \'title\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'undefined author',
        },
        { args      => { project_id => $proj->id,
                         author => '',
                       },
          exception => qr/Field \'title\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'void author',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                       },
          exception => qr/Field \'title\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'project_id and author',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => undef,
                       },
          exception => qr/Field \'issue_type\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'undefined title',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => '',
                       },
          exception => qr/Field \'issue_type\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'void title',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                       },
          exception => qr/Field \'issue_type\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'project_id, author and title',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => undef,
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'undefined issue_type',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => '',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'void issue_type',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'bug',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'issue_type = bug',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'issue_type = feature',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'improvement',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'issue_type = improvement',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'wishlist',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'issue_type = description',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'unexpected_type',
                       },
          exception => qr/Field \'description\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'unexpected issue_type',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => undef,
                       },
          exception => qr/Column \'description\' cannot be null/,
          isa       => undef,
          name      => 'undefined description',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => '',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'void description',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'most simple',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => undef,
                       },
          exception => qr/Column \'severity\' cannot be null/,
          isa       => undef,
          name      => 'undefined severity',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => '',
                       },
          exception => qr/Data truncated for column \'severity\'/,
          isa       => undef,
          name      => 'void severity',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'critical',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'severity = critical',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'major',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'severity = major',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'minor',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'severity = minor',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'nitpick',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'severity = nitpick',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'wishlist',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssue',
          name      => 'severity = wishlist',
        },
        { args      => { project_id => $proj->id,
                         author => 'reporter',
                         title => 'test issue',
                         issue_type => 'feature',
                         description => 'this is a test issue.',
                         severity => 'unexpectes_severity',
                       },
          exception => qr/Data truncated for column \'severity\'/,
          isa       => undef,
          name      => 'unexpected severity',
        },
    );

    for my $n ( 0..$#pattern ) {
        my $p = $pattern[$n];
        my $issue;
        eval { $issue = $api->create( $p->{ args } ) };
        like $@, $p->{ exception }, "error in create PATTERN [$p->{name}]': expected \"$p->{ exception }\" but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        defined $issue ?
            isa_ok $issue, $p->{ isa } :
            is $issue, $p->{ isa } ;
    }
};

subtest "update" => sub {
    my $issue = eval {
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count 1;
        };
        $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for add_action',
            issue_type => 'improvement',
            description => 'testdesu',
            severity => 'minor',
        } );
    };

    $api->update( {
        id => $issue->id,
        author  => "daisukem",
        issue_type  => "bug",
        description => "updated status",
        severity    => "critical",
    } );

    my $updated = $api->find($issue->id);
    is $updated->issue_type, "bug";
    is $updated->description, "updated status";
    is $updated->severity, "critical";
};


subtest "add_action" => sub {

    my $issue = eval {
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count 1;
        };
        $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for add_action',
            issue_type => 'improvement',
            description => 'testdesu',
            severity => 'minor',
        } );
    };

    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 0;
    };
    my @pattern = (
        { args      => { project_id => $proj->id,
                       },
          exception => qr/Field \'author\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'project_id only',
        },
        { args      => { project_id => $proj->id,
                         author => undef,
                       },
          exception => qr/Field \'action\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'undefined author',
        },
        { args      => { project_id => $proj->id,
                         author => '',
                       },
          exception => qr/Field \'action\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'void author',
        },
        { args      => { project_id => $proj->id,
                         author => 'azuma',
                       },
          exception => qr/Field \'action\' doesn\'t have a default value/,
          isa       => undef,
          name      => 'project_id and author',
        },
        { args      => { project_id => $proj->id,
                         author => 'azuma',
                         action => undef,
                       },
          exception => qr/Column \'action\' cannot be null/,
          isa       => undef,
          name      => 'undefined action',
        },
        { args      => { project_id => $proj->id,
                         author => 'azuma',
                         action => '',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssueAction',
          name      => 'void action',
        },
        { args      => { project_id => $proj->id,
                         author => 'azuma',
                         action => 'test action',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssueAction',
          name      => 'project_id, author and action',
        },
    );

    for my $n ( 0 .. $#pattern ) {
        my $p = $pattern[$n];
        my $action;
        eval { $action = $api->add_action( $issue->id, $p->{ args } ) };
        like $@, $p->{ exception }, "error in add_action PATTERN [$p->{name}]: expected \"$p->{ exception }\" but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        defined $action ?
            isa_ok $action, $p->{ isa } :
            is $action, $p->{ isa } ;
    }
};

subtest "load_actions" => sub {

    my $issue = eval {
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count 1;
        };
        $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for load_action',
            issue_type => 'improvement',
            description => 'testdesu',
            severity => 'minor',
        } );
    };

    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 0;
    };

    my $action = $api->add_action( $issue->id, {
        project_id => $proj->id,
        author => 'azuma',
        action => 'test_action',
    } );

    my @pattern = (
        { args      => undef,
          exception => qr/^$/,
          rows      => 0,
          name      => 'undefined args',
        },
        { args      => {},
          exception => qr/^$/,
          rows      => 0,
          name      => 'empty args',
        },
        { args      => { issue_id => undef,
                       },
          exception => qr/^$/,
          rows      => 0,
          name      => 'undefined issue_id',
        },
        { args      => { issue_id => 'TEKITOU_ID',
                       },
          exception => qr/^$/,
          rows      => 0,
          name      => 'nonexistent issue_id',
        },
        { args      => { issue_id => $issue->id,
                       },
          exception => qr/^$/,
          rows      => 2,
          name      => 'existent issue_id'
        },
    );

    for my $n ( 0..$#pattern ) {
        my $p = $pattern[$n];
        my @actions;
        eval { @actions = $api->load_actions( $p->{ args } ) };
        like $@, $p->{ exception }, "error in load_actions PATTERN [$p->{name}]: expected \"$p->{ exception }\" but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        is $#actions + 1, $p->{ rows };
        for my $_action ( @actions ) {
            isa_ok $_action, 'Cirque::DB::Row::CirqueIssueAction';
        }
    }
};

subtest "add_comment" => sub {

    my $issue = eval {
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count 1;
        };
        $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for add_comment',
            issue_type => 'improvement',
            description => 'testdata',
            severity => 'minor',
        } );
    };

    my @pattern = (
        { args      => { issue_id => $issue->id,
                       },
          exception => qr/Column \'body\' cannot be null/,
          rows      => 0,
          name      => 'issue_id only',
        },
        { args      => { issue_id => $issue->id,
                         body => undef,
                       },
          exception => qr/Column \'body\' cannot be null/,
          rows      => 0,
          name      => 'undefined body',
        },
        { args      => { issue_id => $issue->id,
                         body => '',
                       },
          exception => qr/Column \'author\' cannot be null/,
          rows      => 0,
          name      => 'void only',
        },
        { args      => { issue_id => $issue->id,
                         body => 'test comment',
                       },
          exception => qr/Column \'author\' cannot be null/,
          rows      => 0,
          name      => 'issue_id and body',
        },
        { args      => { issue_id => $issue->id,
                         body => 'test comment',
                         author => undef,
                       },
          exception => qr/Column \'author\' cannot be null/,
          rows      => 0,
          name      => 'undefined author',
        },
        { args      => { issue_id => $issue->id,
                         body => 'test comment',
                         author => 'azuma',
                       },
          rows      => 1,
          name      => 'issue_id, body, author and project_id',
        },
    );

    for my $n ( 0..$#pattern ) {
        my $p = $pattern[$n];
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count( $p->{exception} ? 0 : 1 );
        };
        eval { $api->add_comment( $issue->id, $p->{ args } ) };

        if ( $p->{exception} ) {
            like $@, $p->{ exception }, "error in add_comment PATTERN [$p->{name}]: expected \"$p->{ exception }\" but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        } else {
            ok !$@, "Excepted no error, got $@";
        }
        my @comments = $api->load_comments( { issue_id => $issue->id } );
        is $#comments + 1, $p->{ rows }, "rows not match in PATTERN $n";
    }
};

subtest "add_file" => sub {
    my $issue = $api->create( {
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'test issue',
        issue_type  => 'feature',
        description => 'issue',
        severity    => 'critical',
    });

    my $attach1 = $api->add_file( $issue->id => {
        author => "reporter",
        filename   => __FILE__,
        mimetype   => "text/plain",
        filesize   => (stat(__FILE__))[7],
        path       => __FILE__,
    } );
    my $attach2 = $api->add_file( $issue->id => {
        author => "reporter",
        filename   => __FILE__,
        mimetype   => "text/plain",
        filesize   => (stat(__FILE__))[7],
        body       => do { open my $fh, '<', __FILE__; $fh }
    } );
    my $attach3 = $api->add_file( $issue->id => {
        author => "reporter",
        filename   => __FILE__,
        mimetype   => "text/plain",
        filesize   => (stat(__FILE__))[7],
        body       => do { open my $fh, '<', __FILE__; local $/; <$fh> }
    } );

    my $body = do { open my $fh, '<', __FILE__; local $/; <$fh> };

    my @files = $api->load_files({
        issue_id => $issue->id,
    });
    is scalar @files, 3, "got 3 files for " . $issue->id;

    foreach my $attach ( $attach1, $attach2, $attach3 ) {
        if (! is $attach->body, $body, "attachment body matches what we sent (should not be encoded)") {
            diag "Expected:";
            diag $body;
            diag "Got:";
            diag $attach->body;
        }

        $api->remove_file( $issue->id => {
            author => "reporter",
            attach_id => $attach->id,
        } );
    }
};

subtest "find_action_by_commit_id" => sub {

    my $issue = eval {
        TODO: {
            todo_skip "Implement email count tests later", 1;
            my $guard = assert_email_count 1;
        };
        $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for find_action_by_commit_id',
            issue_type => 'improvement',
            description => 'test data',
            severity => 'minor',
        } );
    };

    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 0;
    };
    my $action = $api->add_action( $issue->id, {
        project_id => $proj->id,
        author => 'azuma',
        action     => 'test action',
        commit_id  => 'TEST_COMMIT',
    } );

    my @pattern = (
        { args      => undef,
          exception => qr/^$/,
          isa       => undef,
          name      => 'undefined args',
        },
        { args      => {},
          exception => qr/^$/,
          isa       => undef,
          name      => 'empty args',
        },
        { args      => { issue_id => undef,
                       },
          exception => qr/^$/,
          isa       => undef,
          name      => 'undefined issue_id',
        },
        { args      => { issue_id => '',
                       },
          exception => qr/^$/,
          isa       => undef,
          name      => 'void issue_id',
        },
        { args      => { issue_id => 'TEKITOU_ID',
                       },
          exception => qr/^$/,
          isa       => undef,
          name      => 'nonexistent issue_id'
        },
        { args      => { issue_id => $issue->id,
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssueAction',
          name      => 'issue_id only',
        },
        { args      => { issue_id => $issue->id,
                         commit_id => undef,
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssueAction',
          name      => 'undefined commit_id',
        },
        { args      => { issue_id => $issue->id,
                         commit_id => '',
                       },
          exception => qr/^$/,
          isa       => undef,
          name      => 'void commit_id',
        },
        { args      => { issue_id => $issue->id,
                         commit_id => 'TEKITOU_ID',
                       },
          exception => qr/^$/,
          isa       => undef,
          name      => 'nonexistent commit_id',
        },
        { args      => { issue_id => $issue->id,
                         commit_id => 'TEST_COMMIT',
                       },
          exception => qr/^$/,
          isa       => 'Cirque::DB::Row::CirqueIssueAction',
          name      => 'issue_id and commit_id',
        },
    );

    foreach my $n ( 0..$#pattern ) {
        my $p = $pattern[$n];
        my $_action;
        eval { $_action = $api->find_action_by_commit_id( $p->{ args } ) };
        like $@, $p->{ exception }, "error in ind_action_by_commit_id PATTERN [$p->{name}]: expected \"$p->{ exception }\" but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        defined $_action ?
            isa_ok $_action, $p->{ isa } , Dumper( $p ):
            is $_action, $p->{ isa };
    }
};

subtest 'subissue' => sub {
    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 3;
    };
    my $issue = $api->create( {
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'test issue',
        issue_type  => 'feature',
        description => 'parent issue',
        severity    => 'critical',
    });
    my $subissue = $api->create( {
        parent_issue_id => $issue->id,
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'test issue',
        issue_type  => 'feature',
        description => 'child issue',
        severity    => 'critical',
    } );

    ok $issue, "issue created ok";
    ok $subissue, "subissue created ok";

    {
        my @actions = sort {
            $a->action cmp $b->action
        } $ctxt->get('API::IssueAction')->search( { issue_id => $subissue->id } );
        if (is scalar @actions, 1, "want 1 action for subissue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
        }
    }
    {
        my @actions = $ctxt->get('API::IssueAction')->search( { issue_id => $issue->id } );
        if (is scalar @actions, 2, "want 2 actions for issue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
            is $actions[1]->action, "issue.subissue_create";
        }
    }

    {
        my @parent = $api->load_parent_issues( $subissue->id );
        if (is scalar @parent, 1) {
            is $parent[0]->id, $issue->id;
        }
    
        my @children = $api->load_sub_issues( $issue->id );
        if (is scalar @children, 1) {
            is $children[0]->id, $subissue->id;
        }

    }
};

subtest 'set_subissue' => sub {
    TODO: {
        todo_skip "Implement email count tests later", 1;
        my $guard = assert_email_count 5;
    };

    my $issue = $api->create( {
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'test issue',
        issue_type  => 'feature',
        description => 'parent issue',
        severity    => 'critical',
    } );
    my $other_issue = $api->create( {
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'other issue',
        issue_type  => 'feature',
        description => 'other issue',
        severity    => 'critical',
    } );
    my $more_other_issue = $api->create( {
        project_id  => $proj->id,
        author => 'reporter',
        title       => 'more other issue',
        issue_type  => 'feature',
        description => 'more other issue',
        severity    => 'critical',
    } );
    my $child_issue = $api->create( {
        parent_issue_id => $issue->id,
        project_id      => $proj->id,
        author     => 'reporter',
        title           => 'child issue',
        issue_type      => 'feature',
        description     => 'child issue',
        severity        => 'critical',
    } );

    ok $issue, "issue created ok";
    ok $other_issue, "other issue created ok";
    ok $more_other_issue, "more other issue created ok";
    ok $child_issue, "child issue created ok";

    $api->set_subissues( "azuma", $issue->id, $other_issue->id, $more_other_issue->id );

    {
        my @actions = $ctxt->get('API::IssueAction')->search( { issue_id => $issue->id } );
        if (is scalar @actions, 2, "want 2 actions for issue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
            is $actions[1]->action, "issue.subissue_create";
        }
    }
    {
        my @actions = sort {
            $a->action cmp $b->action
        } $ctxt->get('API::IssueAction')->search( { issue_id => $child_issue->id } );
        if (is scalar @actions, 1, "want 1 action for child_issue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
        }
    }
    {
        my @actions = $ctxt->get('API::IssueAction')->search( { issue_id => $other_issue->id } );
        if (is scalar @actions, 1, "want 1 action for other_issue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
        }
    }
    {
        my @actions = $ctxt->get('API::IssueAction')->search( { issue_id => $more_other_issue->id } );
        if (is scalar @actions, 1, "want 1 action for more_other_issue, got " . scalar @actions) {
            is $actions[0]->action, "issue.create";
        }
    }

    {
        my @subissues = $api->load_sub_issues( $issue->id );
        ok( scalar( grep { $_->id eq $other_issue->id } @subissues ) == 1, "other_issue became subissue" );
        ok( scalar( grep { $_->id eq $more_other_issue->id } @subissues ) == 1, "more_other_issue became subissue" );
        ok( scalar( grep { $_->id eq $child_issue->id } @subissues ) == 0, "relation for child_issue was removed" );
    }
};

subtest update_modified => sub {

    my $issue_1 = $api->create( {
        project_id => $proj->id,
        author => 'reporter',
        title => 'test issue',
        issue_type => 'feature',
        description => 'this is a test issue.',
        severity => 'wishlist',
    } );

    sleep 5;
    my $issue_2 = $api->update( {
        id => $issue_1->id,
        title => 'modified',
        author => 'reporter',
    } );

    my $modified_1 = Time::Piece->strptime( $issue_1->modified_on, '%Y-%m-%d %H:%M:%S' );
    my $modified_2 = Time::Piece->strptime( $issue_2->modified_on, '%Y-%m-%d %H:%M:%S' );
    ok $modified_2 > $modified_1;
    
};

subtest hook => sub {
    my $kw_api = $ctxt->get('API::IssueKeyword');
    my $issue = $api->create( {
        project_id => $proj->id,
        author => 'reporter',
        title => random_ascii_string 14,
        issue_type => 'feature',
        description => 'this is a test issue.',
        severity => 'wishlist',
    } );
    my $milestone = $ctxt->get('API::Milestone')->find( $issue->milestone_id );
    my ( $kw ) = $kw_api->search({ issue_id => $issue->id });
    is(
        $kw->keyword, 
        join( ' ',  
            $proj->name, 
            $milestone->name,
            $issue->title,
            $issue->resolution,
            $issue->author,
            $issue->severity,
            $issue->created_on,
            $issue->modified_on,
            $issue->description
       ),
    );

    $api->update( {
        id => $issue->id,
        title => random_ascii_string 12,
        author => 'reporter',
    } );
    $issue = $api->find( $issue->id );
    ( $kw ) = $kw_api->search({ issue_id => $issue->id });
    $milestone = $ctxt->get('API::Milestone')->find( $issue->milestone_id );
    is(
        $kw->keyword, 
        join( ' ',  
            $proj->name, 
            $milestone->name,
            $issue->title,
            $issue->resolution,
            $issue->author,
            $issue->severity,
            $issue->created_on,
            $issue->modified_on,
            $issue->description
       ),
    );

};

subtest search_by_keyword => sub {
    my $issue = $api->create( {
        project_id => $proj->id,
        author => 'reporter',
        title => random_ascii_string 14,
        issue_type => 'feature',
        description => 'this is a test issue.',
        severity => 'wishlist',
    } );
    my @matched = $api->search( { 
        keyword => substr( $issue->title, 2, 6 ) 
    } );
    my @expected = ();
    for my $m ( @matched ) {
        push @expected, $m if $m->title eq $issue->title;
    }
    ok scalar @expected == 1;
};

subtest 'create an issue with git# link in its description' => sub {
    # check if we have internet connectivity and stuff
    
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

        # get current local HEAD
        my ($sha1) = `git log -n 1 --pretty='%H'`;
        chomp $sha1;

        # get current origin HEAD
        my $bare_repo = get_bare_repo( $repo->url );
        my ($remote_sha1) = $bare_repo->( qw( log -n 1 --pretty='%H' ) );

        if ( $sha1 ne $remote_sha1 ) {
            skip "$sha1 is not exists in origin", 1;
        }

        my $issue = $api->create( {
            project_id => $proj->id,
            author => 'azuma',
            title => 'test for add_action',
            issue_type => 'improvement',
            description => <<EOM
git#$sha1 git#$sha1
EOM
        });
        if (! like $issue->description, qr/git#$i#$sha1 git#$i#$sha1/, "properly formatted with git repo ID" ) {
            diag $issue->description;
        }

        my $comment = $api->add_comment( $issue->id, {
                author     => random_ascii_string 12,
                body       => <<EOM
git#$sha1 git#$sha1
EOM
        });

        if (! like $comment->body, qr/git#$i#$sha1 git#$i#$sha1/, "properly formatted with git repo ID (comment)" ) {
            diag $comment->body;
        }
    }
};

done_testing;
