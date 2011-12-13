use Test::More;
use strict;
use File::Spec;
use t::Util qw(create_ctxt);
use Cirque::API::Project;
use Carp ();

my $context = create_ctxt();

my $obj = Cirque::API::Project->new(
    container => $context->container
);

eval {
    foreach my $slug ( qw(foo hog piy pon uni fug member_test aaa) ) {
        $obj->delete({ slug => $slug });
    }
};
diag $@;

isa_ok $obj, 'Cirque::API::Project';

subtest "create_with_no_args" => sub {
    eval { $obj->create() } ;
    ok $@, "excepted error: no arguments";
};

subtest "create_with_name_only" => sub {
    eval { 
        $obj->create( 
            { name => 'foobar' } 
        );
    };
    ok $@, "excepted error: repos and slug are undef";
};

subtest "create_with_repos_only" => sub {
    eval { 
        $obj->create( 
            { 
                repos => [ 
                    { url => 'http://one.foobar.server/foobar.git', name => 'primary' },
                    { url => 'http://two.foobar.server/foobar.git', name => 'secondary' },
                ] 
            } 
        );
    };
    ok $@, "excepted error: name and slug are undef";
};

subtest "create_with_name_and_repos" => sub {
    eval { 
        $obj->create(
            {
                name => 'foobar',
                repos => [ 
                    { url => 'http://one.foobar.server/foobar.git', name => 'primary' },
                    { url => 'http://two.foobar.server/foobar.git', name => 'secondary' },
                ]
            } 
        ); 
    };
    ok $@, "excepted error: slug is undef";
};

subtest "create_succeed" => sub {
    eval {
        my $proj = $obj->create(
            {
                name => 'foobar',
                slug => 'foo',
                repos => [ 
                    { url => 'http://one.foobar.server/foobar.git', name => 'primary' },
                    { url => 'http://two.foobar.server/foobar.git', name => 'secondary' },
                ]
            } 
        );
        isa_ok $proj, 'Cirque::DB::Row::CirqueProject';
        $obj->delete( { id => $proj->id } );
    };
    ok $@ eq '', "no error expected, but got\n$@";
};

subtest "create_select_remove" => sub {
    my @names = qw/ foobar fuga hoge piyo ponyo uniuni /;
    foreach my $name ( @names ) {
        my $proj = $obj->create( {
            name => $name,
            slug => substr( $name, 0, 3 ),
            repos => [
                { url => "http://one.$name.server/$name.git", name => 'primary' },
                { url => "http://two.$name.server/$name.git", name => 'secondary' },
            ]
        } );
        isa_ok $proj, 'Cirque::DB::Row::CirqueProject';

        my @_proj = grep { $_->name eq $name } $obj->all;
        is $#_proj, 0, "matched only 1 row";
        is $_proj[0]->name, $name;
        is $_proj[0]->slug, substr( $name, 0, 3 );

        my @repos = $obj->get_handle( 'DB::Master' )->search( 
            'cirque_repository', 
            { project_id => $proj->id, name => 'secondary' } 
        );
        if (ok scalar @repos > 0, "repos found") {
            $obj->remove_repository( {
                project_id => $proj->id,
                repository_id => $repos[0]->id,
            } );
            @repos = $obj->get_handle( 'DB::Slaves' )->search(
                'cirque_repository',
                { project_id => $proj->id }
            );
            is $#repos, 0;
            is $repos[0]->name, 'primary';
        }
    }
};

subtest "project_member" => sub {
    my $test_member = sub {
        my ( $members, $accounts ) = @_; 
        my $member;
        for my $i ( 0 .. $#{$members} ) {
            $member = ${$members}[$i];
            isa_ok $member, 'Cirque::DB::Row::CirqueProjectMember';
            is $member->get_columns->{account_id}, $accounts->[$i];
        }
    };

    my $proj = $obj->create( {
        name => 'member_test',
        slug => 'member_test',
        repos => [
            { url => "http://foobar.example.com/member_test.git", name => 'repo0' },
        ]
    } );

    my @accounts = qw/ azuma@bts.example.com daisukem@bts.example.com /;

    for my $account_id ( @accounts ) {
        $obj->add_member( { project_id => $proj->id, account_id => $account_id } );
    }

    my @members = $obj->load_members( $proj->id );
    is scalar @members, 2;
    $test_member->( [ @members ], [ @accounts ] );

    $obj->remove_member( { project_id => $proj->id, account_id => $accounts[0] } );
    
    @members = $obj->load_members( $proj->id );
    is scalar @members, 1;
    $test_member->( [ @members ], [ $accounts[1] ] );

};

done_testing;

