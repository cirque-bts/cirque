use Test::More;
use strict;

use File::Spec;
use t::Util qw(create_ctxt);
use Cirque::API::Schema;

my $context = create_ctxt();

my $obj = Cirque::API::Schema->new;

isa_ok $obj, 'Cirque::API::Schema';

subtest 'sql_to_statements' => sub { 

    my $expect = [ 

q{CREATE TABLE stmt_test (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL,
    datein DATETIME NOT NULL
) ENGINE=InnoDB, DEFAULT CHARACTER SET 'utf8'},

q{CREATE TRIGGER stmt_test_datein
    BEFORE INSERT ON stmt_test
    FOR EACH ROW BEGIN
        SET NEW.datein = NOW();
    END},

    ];

    my @stmts = $obj->sql_to_statements( File::Spec->catfile( qw/ t data sql_stmt_01.txt / ) );

    for my $i ( 0 .. $#stmts ) {
        is $stmts[$i], $expect->[$i];
    }

    my $stmts = $obj->sql_to_statements( File::Spec->catfile( qw/ t data sql_stmt_01.txt / ) );
    is_deeply $stmts, $expect;

    eval {
        $obj->sql_to_statements( File::Spec->catfile( qw/ t data non-exists.txt / ) );
    };
    ok $@, "should throw an error";

};

subtest 'installed_version' => sub {

    is $obj->installed_version( $context ), undef;

};

subtest 'is_compatible' => sub {

    ok ! $obj->is_compatible( $context, '0.9' );
    ok $obj->is_compatible( $context, '1.0' );
    ok ! $obj->is_compatible( $context, '1' );

};

done_testing();
