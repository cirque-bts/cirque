package t::lib::App::Prove::Plugin::FixtureGenerator;
use strict;
use DBI;
use Test::More;

sub dbh {
    diag "Connecting to $ENV{TEST_DSN}";
    return DBI->connect( $ENV{TEST_DSN}, undef, undef, {
        RaiseError => 1,
        AutoCommit => 1,
        mysql_enable_utf8 => 1,
    });
}

sub _random {
    my $num = shift;
    my @list = ('a'..'z', 'A'..'Z', '0'..'9');
    join "", map { $list[rand @list ] } (1..$num);
}

sub load {
    # API key/secret

    diag "Generating API key/secret for Cirque webapp...";
    my $api_key = $ENV{ CIRQUE_WEB_API_KEY } = _random( 12 );
    my $api_secret = $ENV{ CIRQUE_WEB_API_SECRET } = _random( 40 );

    my $dbh = dbh();
    $dbh->do(
        qq|REPLACE INTO cirque_servicer ( id, name, api_key, api_secret ) VALUES ( "cirque_web", "Cirque Webapp", ?, ? )|,
        undef,
        $api_key,
        $api_secret
    );
}

1;
