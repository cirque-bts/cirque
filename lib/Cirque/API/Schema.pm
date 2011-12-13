package Cirque::API::Schema;
use Mouse;

sub sql_to_statements {
    my ($self, $file) = @_;

    open my $fh, '<', $file or die "could not open file $file: $!";
    my $eos = ";";
    my @buffer;
    my @statements;

    my $to_statement = sub {
        my $stmt = join '', @_;
        $stmt =~ s/^\s+//;
        $stmt =~ s/\s+$//;
        return $stmt;
    };

    while ( my $ln = <$fh> ) {
        if ( $ln =~ /^\s*DELIMITER\s+(\S+)\s*/ ) {
            $eos = $1;
        }
        else {
            push @buffer, $ln;
            if ( $buffer[-1] =~ s/\Q$eos\E$// ) {
                my $stmt = $to_statement->( @buffer );
                push @statements, $stmt if $stmt;
                @buffer = ();
            }
        }
    }

    if ( @buffer ) {
        my $stmt = $to_statement->( @buffer );
        push @statements, $stmt if $stmt;
    }

    return wantarray ? @statements : \@statements;
}

sub installed_version {
    my ($self, $ctxt) = @_;

    my $dbh = $ctxt->get('DB::Master')->dbh;
    my ($version) = $dbh->selectrow_array( "SELECT value FROM cirque_installation WHERE id = ?", undef, "version" );
    return $version;
}

sub is_compatible {
    my ($self, $ctxt, $v) = @_;
    return ($v eq '1.0');
}

sub install {
    my ($self, $ctxt, $version) = @_;

    my $stmts = $self->sql_to_statements( $ctxt->path_to( "misc", "cirque.sql" ) );
    my $dbh = $ctxt->get('DB::Master');

    foreach my $stmt (@$stmts) {
        $dbh->do( $stmt );
    }
    $dbh->do(<<EOSQL, undef, $version);
        INSERT INTO cirque_installation ( id, value ) VALUES ( "version", ? );
EOSQL

    print "*** Installed schmea version $version\n";

}

no Mouse;

__PACKAGE__->meta->make_immutable();
1;

