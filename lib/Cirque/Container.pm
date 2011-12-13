package Cirque::Container;
use Cirque::Pragmas;
use Mouse;
use Scope::Guard ();

foreach my $opt ( qw(objects registry scoped_registry) ) {
    has $opt => (
        is => 'rw',
        isa => 'HashRef',
        default => sub { +{} }
    );
}

has scoped_objects => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

sub new_scope {
    my $self = shift;
    Scope::Guard->new(sub {
        $self->scoped_objects({});
    } );
}

sub register {
    my ($self, $key, $thing, $opts) = @_;

    $opts ||= {};
    if (ref $thing eq 'CODE') {
        if ($opts->{scoped}) {
            $self->scoped_registry->{$key} = $thing;
        } else {
            $self->registry->{$key} = $thing;
        }
    } else {
        $self->objects->{$key} = $thing;
    }
}

sub get {
    my ($self, $key) = @_;

    my $object;
    my $is_scoped = exists $self->scoped_registry->{$key};
    if ( $is_scoped ) {
        # if it's scoped, use scope_container
        $object = $self->scoped_objects->{$key};
    } else {
        # if it's a regular object, just try to grab it
        $object = $self->objects->{$key};
    }

    if (! $object) {
        my $code;
        if ( $is_scoped ) {
            my $code = $self->scoped_registry->{$key};
            if ($object = $code->($self)) {
                $self->scoped_objects->{$key} = $object;
            }
        } elsif ( $code = $self->registry->{$key} ) {
            if ( $object = $code->($self) ) {
                $self->objects->{$key} = $object;
            }
        }
    }

    if ( ! $object) {
        Carp::confess("$key could not be found in container");
    }

    return $object;
}

no Mouse;

1;

