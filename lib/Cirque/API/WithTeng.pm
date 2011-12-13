package Cirque::API::WithTeng;
use Mouse::Role;
use Carp ();
use Cirque::Util qw(random_uuid);
use Time::Piece;

with qw(
    Cirque::Trait::WithCache 
    Cirque::Trait::WithContainer
);

has handles => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has primary_key => (
    is => 'ro',
    isa => 'Str',
    default => 'id'
);

has has_uuid_pk => (
    is => 'ro',
    isa => 'Bool',
);

has table => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_table {
    my $self = shift;
    ( blessed $self) =~ /^Cirque::API::(.*)/;
    my $p = $1;
    my @v = ('cirque');
    while ( $p =~ m/([A-Z0-9][^A-Z]+)/sgx ) {
        my $match = $1;
        $match =~ s/:://g;
        push @v, lc($match);
    }
    return join '_', @v;
}

sub get_handle {
    my ($self, $name) = @_;

    # if $self->{FORCE_HANDLE} is set (local $self->{FORCE_HANDLE} = 'DB::Master')
    # then use that handle regardless
    if ( $self->{FORCE_HANDLE} ) {
        $name = $self->{FORCE_HANDLE};
    }
    # warn "get_handle $name";
    my $handles = $self->container->get($name);
    if ( $handles && ref $handles ne 'ARRAY' ) {
        $handles = [ $handles ];
    }
    foreach my $handle (List::Util::shuffle( @$handles )) {
        if ($handle->dbh->ping) {
            return $handle;
        }
    }

    Carp::confess("Could not find handle by name $name");
}

sub cache_key {
    my ($self, $pk) = @_;
    Carp::croak( 'pk is not defined' ) unless defined $pk;
    return join('.', $self->table, $self->primary_key, $pk);
}

sub txn_scope {
    my $self = shift;
    my $handle = $self->get_handle('DB::Master');
    return $handle->txn_scope();
}

sub find {
    my ($self, $pk) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    my $row;

    my $cache_key;
    my $cache = $self->cache;
    if ($cache) {
        $cache_key = $self->cache_key($pk);
        my $data = $cache->get( $cache_key );
        # warn "find($pk) [$cache_key]: " . ( $data ? "HIT" : "MISS" );
        if ( $data ) {
            $row = $data;
            $row->{teng} = $handle;
        }
    }

    if (! $row) {
        $row = $handle->single( $self->table, { $self->primary_key => $pk } );
        # warn "find($pk): $row";
        if (defined $row && $cache) {
            local $row->{teng};
            $cache->set( $cache_key, $row );
        }
    }
    return $row;
}

sub create {
    my ($self, $args, $handle) = @_;
    $handle ||= $self->get_handle('DB::Master');
    if ($self->has_uuid_pk) {
        $args->{ $self->primary_key } ||= random_uuid( $self, $args );
    }
    my $row = $handle->insert( $self->table, $args );
    if (my $cache = $self->cache) {
        my $pk = $args->{ $self->primary_key };
        if (defined $pk) {
            my $cache_key = $self->cache_key($pk);
            local $row->{teng};
            # warn "create($row): SET $cache_key";
            $cache->set( $cache_key, $row );
        }
    }
    return $row;
}

sub search {
    my ($self, $cond, $args) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    return $handle->search($self->table, $cond, $args);
}

sub unique_key {
    my ($class, @keys) = @_;
    foreach my $key_name ( @keys ) {
        my $fqname = "find_by_$key_name";
        $class->meta->add_method( $fqname => sub {
            my ($self, $id) = @_;
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            my $handle = $self->get_handle('DB::Slaves');
            my $row = $handle->single( $self->table, { $key_name => $id } );
            return $row;
        });
    }
}

sub update {
    my ($self, $args) = @_;
    my $pk = delete $args->{ $self->primary_key }
        or Carp::croak( "No primary key provided for update()" );
    my $handle = $self->get_handle('DB::Master');
    my $row    = $self->find( $pk )
        or Carp::croak( "No row by id $pk found" );

    if ( $row->can('modified_on') ) {
        $args->{modified_on} = localtime->strftime('%Y-%m-%d %H:%M:%S');
    }

    if ($row->update($args)) {
        if (my $cache = $self->cache) {
            my $cache_key = $self->cache_key($pk);
            local $row->{teng};
            $cache->set( $cache_key, $row );
        }
    }

    return $row;
}

sub delete {
    my ($self, $args) = @_;

    # XXX Inefficient, grrr
    my @objects = $self->search( $args );
    $self->get_handle('DB::Master')->delete( $self->table, $args );
    if ( my $cache = $self->cache ) {
        my $pk_field = $self->primary_key;
        foreach my $object ( @objects ) {
            my $cache_key = $self->cache_key( $object->$pk_field );
            $cache->delete( $cache_key );
        }
    }
    return scalar @objects || ();
}

sub delete_from_cache {
    my ($self, $args) = @_;
    my @objects = $self->search( $args );
    if ( my $cache = $self->cache ) {
        my $pk_field = $self->primary_key;
        for my $object ( @objects ) {
            my $cache_key = $self->cache_key( $object->$pk_field );
            $cache->delete( $cache_key );
        }
    }
    return scalar @objects || ();
}

no Mouse::Role;

1;
