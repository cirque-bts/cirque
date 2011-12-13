use Test::More;
use strict;

use File::Spec;
use t::Util qw(create_ctxt);
use Cirque::API::Milestone;
use Cirque::API::Project;

my $context = create_ctxt();


subtest "get_handle" => sub {
    my $obj = Cirque::API::Milestone->new( container => $context->container );

    my @pattern = (
        { args      => 'DB::Slaves', 
          isa       => qr/^Cirque\:\:DB$/, 
          exception => qr/^$/,
        },
        { args      => 'NotExists', 
          isa       => qr/^$/,
          exception => qr/NotExists could not be found in container/,
        },
    );

    sub {
        my $n = shift;
        my $p = $pattern[$n];
        my $handle;
        eval { $handle = $obj->get_handle( $p->{ args } ) };
        like $@, $p->{ exception }, "error in get_handle PATTERN $n: expected \"$p->{ exception }\", but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        if ( defined $handle ) {
            like ref $handle, $p->{ isa }, "unmatched class-type in get_handle PATTERN $n: expected $p->{ isa }, but got ".ref $handle."\n--- args ---\n".explain( $p->{ args } );
        }
    }->( $_ ) for 0 .. $#pattern;
};

subtest "cache_key" => sub {
    my $obj = Cirque::API::Project->new( container => $context->container );
    my ( $proj ) = $obj->search( { name => 'foobar' } );
    isa_ok $proj, 'Cirque::DB::Row::CirqueProject';

    my @pattern = (
        { args      => 'HOGEHOGE',
          exception => qr/^$/,
          key       => 'cirque_project.id.HOGEHOGE',
        },
        { args      => $proj->id,
          exception => qr/^$/,
          key       => 'cirque_project.id.'.$proj->id,
        },
    );

    sub {
        my $n = shift;
        my $p = $pattern[$n];
        my $key;
        eval { $key = $obj->cache_key( $p->{ args } ) };
        like $@, $p->{ exception }, "error in cache_key PATTERN $n: expected \"$p->{ exception }\", but got \"$@\"\n--- args ---\n".explain( $p->{ args } );
        is $key, $p->{ key }, "unmatched key in cache_key PATTERN $n: expected \"$p->{ key }\", but got \"$key\"\n--- args ---\n".explain( $p->{ args } );
    }->( $_ ) for 0 .. $#pattern;
};

subtest "update" => sub {
    my $obj = Cirque::API::Project->new( container => $context->container );
    my $proj;
    my @pattern = (
        { name        => 'foobar',
          description => 'foobarbaz',
          exception   => qr/^$/,
          update      => sub {
                             my ( $obj, $proj, $p ) = @_;
                             $obj->update( {
                                 $obj->primary_key => $proj->id,
                                 description => $p->{ description },
                             } );
                         },
        },
        { name        => 'NotFound',
          description => 'wooo',
          exception   => qr/Can\'t call method \"id\" on an undefined value/,
          update      => sub {
                             my ( $obj, $proj, $p ) = @_;
                             $obj->update( {
                                 $obj->primary_key => $proj->id,
                                 description => $p->{ description },
                             } );
                         },
        },
        { name        => 'foobar',
          description => 'foobarbaz',
          exception   => qr/No row by id NotFound found/,
          update      => sub {
                             my ( $obj, $proj, $p ) = @_;
                             $obj->update( {
                                 $obj->primary_key => "NotFound",
                                 description => $p->{ description },
                             } );
                         },
        },
    );

    sub {
        my $n = shift;
        my $p = $pattern[$n];
        ( $proj ) = $obj->search( { name => $p->{ name } } );
        eval { $p->{ update }->( $obj, $proj, $p ) };
        like $@, $p->{ exception }, 
            sprintf <<EOM, $n, $p->{ exception } || '(null)', $@, explain $p;
error in update PATTERN %d: expected "%s", but got "%s"
--- pattern ---
EOM

        ( $proj ) = $obj->search( { name => $p->{ name } } );
        is $proj->description, $p->{ description }, "new description is '$p->{ description }'"
            if defined $proj;

    }->( $_ ) for 0 .. $#pattern;

    eval{ $obj->update( { description => 'abc' } ) };
    like $@, qr/No primary key provided for update/, "error in update without primary_key.";
};

done_testing;
