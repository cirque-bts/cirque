use strict;
use Test::More;
use t::Util qw(create_ctxt start_plackup api_credential);
use Cirque::Util qw(random_ascii_string);

sub make_slug {
    my $slug;
    do {
        $slug = random_ascii_string 12;
    } while ( $slug =~ /^[^A-Za-z0-9]/ );
    return $slug;
}

sub flush_projects {
    my $rpc = shift;
    my $projects = $rpc->project_projects;
    for my $p ( @$projects ) {
        $rpc->project_delete( { id => $p->{id} } );
    }
}

sub flush_users {
    my $rpc = shift;
    my $users = $rpc->user_search({});
    for my $user ( @$users ) {
        $rpc->user_delete( { id => $user->{id} } );
    }
}

sub create_dummy_project {
    my $rpc = shift;
    my $project = $rpc->project_create( {
        slug => make_slug(),
        name => 'DummyProject',
        description => 'Test',
    } );
    return $project;
}


my $server = start_plackup "t/jsonrpc.psgi";
$ENV{TEST_RPC_PORT} = $server->port;

my $ctxt = create_ctxt;
my $rpc = $ctxt->get( 'API::RPC' );

isa_ok $rpc, 'Cirque::API::RPC';

subtest project_cleanup => sub {
    my $projects = $rpc->project_projects;
    isa_ok $projects, 'ARRAY';

    for my $p ( @$projects ) {
        $rpc->project_delete( { id => $p->{id} } );
    }

    $projects = $rpc->project_projects;
    isa_ok $projects, 'ARRAY';
    is scalar @$projects, 0;
};

subtest project => sub {
    my $slug = make_slug();
    my $project = $rpc->project_create( {
        slug => $slug,
        name => 'MyPJ',
        description => 'example',
    } );
    isa_ok $project, 'HASH';
    is $project->{name}, 'MyPJ';
    is $project->{slug}, $slug;

    $rpc->project_create( {
        slug => make_slug(),
        name => 'monimoni',
        description => 'foobar',
    } );

    my $projects = $rpc->project_projects;
    is scalar @$projects, 2;

    my $fetched = $rpc->project_fetch( { slug => $project->{slug} } );
    isa_ok $fetched, 'HASH';
    is $fetched->{name}, $project->{name};

    $rpc->project_update( { id => $project->{id}, name => 'FOOBAR' } );
    $fetched = $rpc->project_fetch( { slug => $project->{slug} } );
    is $fetched->{name}, 'FOOBAR';

    flush_projects( $rpc );
};

subtest repository => sub {
    my $project = create_dummy_project( $rpc );

    my $repository = $rpc->repository_create( {
        project_id => $project->{id},
        name => 'repo 1',
        url => 'http://dummy/hoge.git',
    } );
    isa_ok $repository, 'HASH';
    is $repository->{name}, 'repo 1';

    $project = $rpc->project_fetch( { slug => $project->{slug} } );
    isa_ok $project->{repositories}, 'ARRAY';
    is scalar @{$project->{repositories}}, 1;
    is $project->{repositories}->[0]->{name}, $repository->{name};

    $rpc->repository_update( { id => $repository->{id}, name => 'Development' } );
    $project = $rpc->project_fetch( { slug => $project->{slug} } );
    isa_ok $project->{repositories}, 'ARRAY';
    is scalar @{$project->{repositories}}, 1;
    is $project->{repositories}->[0]->{name}, 'Development';

    flush_projects( $rpc );
};

subtest milestone => sub {
    my $project = create_dummy_project( $rpc );

    my $milestone = $rpc->milestone_create( {
        project_id => $project->{id},
        name       => 'first release',
        due_on     => '2014-12-13 10:00:00',
    } );

    isa_ok $milestone, 'HASH';
    is $milestone->{project_id}, $project->{id};
    is $milestone->{name}, 'first release';
    is $milestone->{due_on}, '2014-12-13 10:00:00';

    $rpc->milestone_update( { id => $milestone->{id}, name => 'FIRST RELEASE' } );
    $milestone = $rpc->milestone_fetch( { id => $milestone->{id} } );
    is $milestone->{name}, 'FIRST RELEASE';

    flush_projects( $rpc );
};

subtest issue => sub {
    my $project = create_dummy_project( $rpc );

    my $issue = $rpc->issue_create( {
        author => 'hogehoge@example.com',
        title => 'Testtest',
        project_id => $project->{id},
        issue_type => 'improvement',
        severity => 'major',
        description => 'Test issue',
        target => 'test',
    } );
    isa_ok $issue, 'HASH';
    is $issue->{author}, 'hogehoge@example.com';
    is $issue->{title}, 'Testtest';
    is $issue->{project_id}, $project->{id};

    my $fetched = $rpc->issue_fetch( { id => $issue->{id} } );
    for my $key ( qw/ author title project_id / ) {
        is $fetched->{"$key"}, $issue->{"$key"};
    }

    $rpc->issue_update( { 
        id => $issue->{id}, 
        title => 'FOOFOO', 
        author => 'oreore@example.com',
    } );

    my $comment = $rpc->issue_comment_create( {
        issue_id => $issue->{id},
        body => 'This is a comment',
        author => 'me@example.com',
    } );
    isa_ok $comment, 'HASH';
    is $comment->{issue_id}, $issue->{id};
    is $comment->{body}, 'This is a comment';
    is $comment->{author}, 'me@example.com'; 

    my $fetched = $rpc->issue_fetch( { id => $issue->{id} } );
    is $fetched->{title}, 'FOOFOO';
    is $fetched->{author}, $issue->{author};

    my $actions = $rpc->issue_actions( { issue_id => $issue->{id} } );
    isa_ok $actions, 'ARRAY';
    is scalar @$actions, 3;
    is $actions->[0]->{message}, "added issue 'Testtest'";
    is $actions->[1]->{message}, "Changed field title from 'Testtest' to 'FOOFOO'";
    is $actions->[2]->{message}, "added a comment";

    my $comments = $rpc->issue_comments( { issue_id => $issue->{id} } );
    isa_ok $comments, 'ARRAY';
    is scalar @$comments, 1;
    is_deeply $comment, $comments->[0];

    my $subissue = $rpc->issue_create( {
        author => 'higashi@tonton.test',
        title => 'SubIssue',
        project_id => $project->{id},
        severity => 'minor',
        issue_type => 'bug',
        description => 'This is a sub-issue.',
        target => 'me',
    } );

    $rpc->issue_set_subissues( { issue_id => $issue->{id}, subissues => [ $subissue->{id} ] } );

    $issue = $rpc->issue_fetch( { id => $issue->{id} } );
    isa_ok $issue->{children}, 'ARRAY';
    is scalar @{$issue->{children}}, 1;
    my $children = $issue->{children}->[0];
    for my $key ( qw/ children parents / ) {
        delete $children->{$key};
        delete $subissue->{$key};
    }
    is_deeply $children, $subissue;

    flush_projects( $rpc );
};

subtest preview => sub {
    my $project = create_dummy_project( $rpc );

    my %args = (
        author => 'hogehoge@example.com',
        title => 'Testtest',
        project_id => $project->{id},
        issue_type => 'improvement',
        severity => 'major',
        description => 'Test issue',
        target => 'test',
    );
    my $res = $rpc->issue_preview( \%args );
    isa_ok $res, 'HASH';
    for my $key ( keys %args ) {
        is $res->{"$key"}, $args{"$key"};
    }

    my $issue = $rpc->issue_create( \%args );

    %args = (
        issue_id => $issue->{id},
        body => 'This is a comment',
        author => 'me@example.com',
    );
    $res = $rpc->issue_comment_preview( \%args );
    isa_ok $res, 'HASH';
    for my $key ( keys %args ) {
        is $res->{"$key"}, $args{"$key"};
    }

    flush_projects( $rpc );
};

subtest user => sub {
    flush_users( $rpc );

    my $user = $rpc->user_create( {
        account_id => 'foobar@example.com',
        name => 'foobar',
        icon => 'http://hoge/fuga.jpg',
    } );
    isa_ok $user, 'HASH';
    is $user->{account_id}, 'foobar@example.com';
    is $user->{name}, 'foobar';

    my $fetched = $rpc->user_fetch( { id => $user->{id} } );
    isa_ok $fetched, 'HASH';
    for my $key ( qw/ account_id name / ) {
        is $fetched->{name}, $user->{name};
    }

    my $notify = $rpc->user_get_notify_checked( { account_id => $user->{account_id} } );
    isa_ok $notify, 'HASH';
    is $notify->{notify_checked}, '0000-00-00 00:00:00';

    $rpc->user_notify_checked( { account_id => $user->{account_id} } );
    
    $notify = $rpc->user_get_notify_checked( { account_id => $user->{account_id} } );
    isa_ok $notify, 'HASH';
    isnt $notify->{notify_checked}, '0000-00-00 00:00:00';

    flush_users( $rpc );
};

subtest project_member => sub {
    flush_users( $rpc );
    my $project = create_dummy_project( $rpc );

    my $user = $rpc->user_create( {
        account_id => 'foobar@example.com',
        name => 'foobar',
        icon => 'http://hoge/fuga.jpg',
    } );

    $rpc->project_member_add( { 
        project_id => $project->{id}, 
        account_id => $user->{account_id},
        author => $user->{account_id},
    } );

    my $fetched = $rpc->project_fetch( { id => $project->{id} } );

    isa_ok $fetched->{members}, 'ARRAY'; 
    is scalar @{$fetched->{members}}, 1;
    is $fetched->{members}->[0], $user->{account_id};

    flush_projects( $rpc );
    flush_users( $rpc );
};

done_testing;
