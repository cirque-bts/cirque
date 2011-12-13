package Cirque::Setup;
use Mouse;

sub needs_setup {
    my ($self, $c) = @_;

print <<EOM;
**** Welcome to Cirque! ***

Initializing environment...
EOM

    Mouse::Util::load_class('Cirque::API::Schema');
    my $schema_api = Cirque::API::Schema->new();

    my $installed = eval {
        $schema_api->installed_version( $c );
    };

    if ($installed) {
        print <<EOM;
Detected Cirque schema version $installed.
EOM
    } else {
        print <<EOM;

***** WHOA THERE! *****

Could not detect installed version from the database.
Perhaps this is the first time you run Cirque?

EOM
        return 1;
    }

    if (! $schema_api->is_compatible( $c, $installed )) {
        print <<EOM;

***** WHOA THERE! *****

Installed schema version '$installed' does not match!

EOM
        return 1;
    }
    return ();
}

sub setup {
    my ($self, $c) = @_;

    print <<EOM;
Installing database schema from scratch....
EOM
    Mouse::Util::load_class('Cirque::API::Schema');
    my $schema_api = Cirque::API::Schema->new();
    my $installed = "1.0";
    $schema_api->install( $c, $installed );
}

no Mouse;

1;
