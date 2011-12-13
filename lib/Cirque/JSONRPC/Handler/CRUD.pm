package Cirque::JSONRPC::Handler::CRUD;
use Cirque::Pragmas;
use Mouse;

has name => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $pkg = blessed $self;
        $pkg =~ s/^Cirque::JSONRPC::Handler:://;
        return $pkg;
    }
);

has namespace => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $namespace = $self->name;
        $namespace =~ s/::/_/g;
        $namespace =~ s/([a-z])([A-Z])/${1}_${2}/g;
        return lc $namespace;
    }
);

sub fetch {
    my ( $self, $params, $procedure, $c ) = @_;

    my $name = $self->name;
    my $namespace = $self->namespace;
    my $api = $c->get("API::$name");

    my $res = $c->get('Validator')->check( $params, "fetch_${namespace}" );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }
    
    my $obj;
    if (my $id = $res->valid('id')) {
        $obj = $api->find( $id );
    }

    if (! $obj ) {
        die( "Could not find associated object\n" );
    }

    return $obj->get_columns;
}

sub search {
    my ( $self, $params, $procedure, $c ) = @_;

    my $name = $self->name;
    my $namespace = $self->namespace;
    my $api = $c->get( "API::$name" );
    my @matched = $api->search( $params->{where}, $params->{options} );
    return [ map { $_->get_columns } @matched ];
};

my $meta = __PACKAGE__->meta;
foreach my $method ( qw(create update delete) ) {
    # XXX delete doesn't quite work the same as create/update...
    # ALMOST! grrrr.
    my $return = $method eq 'delete' ?
        qq|return \$ret ? {} : die "Could not delete object (no matching object)";\n| :
        qq|return { id => \$ret->id };\n|
    ;
    $meta->add_method( $method => eval sprintf <<'EOSUB', $return );
        sub {
            my ( $self, $params, $procedure, $c ) = @_;
            my $name = $self->name;
            my $namespace = $self->namespace;
            my $res = $c->get('Validator')->check( $params, "${method}_${namespace}" );
            if ( ! $res->success ) {
                die( $self->create_validation_error_message( $res ) );
            }
            my $api = $c->get("API::$name");
            my $ret = $api->$method(scalar $res->valid);
            %s
        }
EOSUB
}

sub create_validation_error_message {
    my ($self, $res) = @_;

    my %errors;
    if ( $res->has_missing ) {
        foreach my $field ( $res->missing ) {
            $errors{$field} ||= [];
            push @{$errors{$field}}, "missing";
        }
    }

    if ( $res->has_invalid ) {
        foreach my $field ( $res->invalid ) {
            $errors{$field} ||= [];
            push @{$errors{$field}}, "invalid";
        }
    }

    my $message = "Validation failed:\n";
    foreach my $field ( keys %errors ) {
        $message .= "   $field = [ " . join( ", ", @{ $errors{$field} } ) . " ]\n";
    }
    return $message;
}

no Mouse;

1;
