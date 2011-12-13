use Test::More;
use strict;

use File::Spec;
use t::Util qw(create_ctxt);
use Cirque::Util qw(random_ascii_string);
use Cirque::API::Repository;

my $repo;
my $repos;

my $ctxt = create_ctxt();

my $obj = $ctxt->get( 'API::Repository' );

isa_ok $obj, 'Cirque::API::Repository';

my $proj = $ctxt->get('API::Project')->create( {
    name => random_ascii_string 12,
    slug => random_ascii_string 10,
    repos => [
        { url => "http://foobar.example.com/member_test.git", name => 'repo0' },
    ]
} );


my $api = $ctxt->get('API::Issue');

subtest "default link_patterns" => sub {
    my $repo = $obj->create({
        name       => random_ascii_string 12,
        project_id => $proj->id,
        url        => "git://github.com/dummy/repo.git",
    });
    is $repo->link_pattern, "https://github.com/dummy/repo/commit/%commit";
};

subtest "load_by_project" => sub {
    my @pattern = (
        { proj_id => undef, exception => '', rows => 0 },
        { proj_id => 'IT IS NOT REALLY EXISTS', exception => '', rows => 0 },
        { proj_id => $proj->id, exception => '', rows => 2 },
    );

    foreach my $p (@pattern) {
        eval {
            $repos = $obj->load_by_project( $p->{ proj_id } )
        };
        is $@, $p->{ exception }, "Expected exception '$p->{exception}', got $@";
        is scalar @$repos, $p->{ rows }, "Expected $p->{rows} repos, got @{[ scalar @$repos ]}";
    }
};

subtest "add_branch" => sub {
    $repos = $obj->load_by_project( $proj->id );
    my @pattern = (
        { args      => undef,
          exception => qr/Column \'repository_id\' cannot be null/,
        },
        { args      => {},
          exception => qr/Column \'repository_id\' cannot be null/,
        },
        { args      => { repository_id => $repos->[0]->id,
                       },
          exception => qr/Column \'name\' cannot be null/,
        },
        { args      => { name => 'newrepos',
                       },
          exception => qr/Column \'repository_id\' cannot be null/,
        },
        { args      => { repository_id => $repos->[0]->id,
                         name          => 'newrepos',
                         sha1          => 'SHA1-string',
                         is_head       => 1,
                       },
          exception => qr/^$/,
        },
        { args      => { repository_id => $repos->[0]->id,
                         name          => 'newrepos',
                         sha1          => 'SHA1-string',
                         is_head       => 1,
                       },
          exception => qr/^$/,
        },
    );

    sub {
        my $n = shift;
        my $p = $pattern[ $n ];
        eval { $obj->add_branch( $p->{ args } ) };
        like $@, $p->{ exception }, "exception is not match in add_branch PATTERN $n";
    }->( $_ ) for 0 .. $#pattern;
};

subtest "load_branches" => sub {
    $repos = $obj->load_by_project( $proj->id );
    my @pattern = (
        { args      => undef,
          exception => qr/^$/,
          rows => 0,
        },
        { args      => {},
          exception => qr/^$/,
          rows => 0,
        },
        { args      => { repository_id => undef },
          exception => qr/^$/,
          rows => 0,
        },
        { args      => { repository_id => 'IT IS NOT REALLY EXISTS' },
          exception => qr/^$/,
          rows => 0,
        },
        { args      => { repository_id => $repos->[0]->id },
          exception => qr/^$/,
          rows => 1,
        },
    );

    sub {
        my $n = shift;
        my $p = $pattern[ $n ];
        my @branches;
        eval { @branches = $obj->load_branches( $p->{ args } ) };
        like $@, $p->{ exception }, "exception is not match in load_branches PATTERN $n";
        is $#branches + 1, $p->{ rows }, "rows is not match in load_branches PATTERN $n";
    }->( $_ ) for 0 .. $#pattern;
};

subtest "clear_branches" => sub {
    $repos = $obj->load_by_project( $proj->id );
    my @pattern = (
        { args      => undef,
          exception => qr/^$/,
          quantity  => 1,
        },
        { args      => {},
          exception => qr/^$/,
          quantity  => 1,
        },
        { args      => { repository_id => undef },
          exception => qr/^$/,
          quantity  => 1,
        },
        { args      => { repository_id => 'IT IS NOT REALLY EXISTS' },
          exception => qr/^$/,
          quantity  => 1,
        },
        { args      => { repository_id => $repos->[0]->id },
          exception => qr/^$/,
          quantity  => 0,
        },
    );

    my $check_quantity = sub {
        my @branches = $obj->load_branches( { repository_id => $repos->[0]->id } );
        my $cnt = @branches;
        return $cnt;
    };

    sub {
        my $n = shift;
        my $p = $pattern[ $n ];
        eval { $obj->clear_branches( $p->{ args } ) };
        like $@, $p->{ exception }, "exception is not match in clear_branches PATTERN $n";
        is $check_quantity->(), $p->{ quantity }, "quantity is not match in clea_branches PATTERN $n";
    }->( $_ ) for 0 .. $#pattern;
};

done_testing;
