package Cirque::API::Repository;
use Cirque::Pragmas;
use Mouse;

with qw(Cirque::API::WithTeng);

has '+has_uuid_pk' => (
    default => 1
);

my %link_patterns = (
    q{github\.com[:/]([^/]+/.+)\.git$} => sub {
        sprintf "https://github.com/%s/commit/%%commit", $1;
    }
);

around create => sub {
    my ($next, $self, $args, $handle) = @_;

    # XXX This needs to go into the validation process or something
    if ( ! $args->{link_pattern} ) {
        my $url = $args->{url};
        foreach my $pattern (keys %link_patterns) {
            if ($url =~ m{$pattern} ) {
                $args->{link_pattern} = $link_patterns{$pattern}->();
                last;
            }
        }
    }

    $self->$next($args, $handle);
};

sub load_by_project {
    my ($self, $project_id) = @_;

    my @list = $self->search( { project_id => $project_id } );
    my $handle = $self->get_handle('DB::Master');
    foreach my $repo ( @list ) {
        $repo->{_get_column_cached}->{branches} = [
            $handle->search( cirque_branch => { repository_id => $repo->id } )
        ];
    }
    return [ @list ];
}

sub clear_branches {
    my ($self, $args) = @_;
    my $repository_id = $args->{repository_id};
    my $handle = $self->get_handle('DB::Master');
    $handle->delete( cirque_branch => { repository_id => $repository_id } );
}

sub add_branch {
    my ($self, $args) = @_;

    foreach my $k (qw(repository_id name is_head sha1)) {
        if (! defined $args->{$k}) {
            Carp::croak( "Column '$k' cannot be null" );
        }
    }

    my $repository_id = $args->{repository_id};
    my $name          = $args->{name};
    my $is_head       = $args->{is_head};
    my $sha1          = $args->{sha1};
    my $handle = $self->get_handle('DB::Master');

    my $prev = $handle->single( "cirque_branch" => {
        repository_id => $repository_id,
        name          => $name,
        is_head       => $is_head,
    } );
    if ( ! $prev ) {
        $handle->insert( "cirque_branch" => {
            id            => $self->get('UUID')->create_from_name_str( __PACKAGE__, 
                join ".", $repository_id, $name, $is_head, time(), rand(), $$, {}
            ),
            repository_id => $repository_id,
            name          => $name,
            sha1          => $sha1,
            is_head       => $is_head,
        });
    }
}

sub load_branches {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Master');

    $handle->search( cirque_branch => {
        repository_id => $args->{repository_id},
    } );
}

no Mouse;

1;
