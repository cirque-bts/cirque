package Cirque::API::Project;
use Cirque::Pragmas;
use Mouse;
use Cirque::Util ();

with qw(Cirque::API::WithTeng);

__PACKAGE__->unique_key( 'slug' );

around create => sub {
    my ($next, $self, $args) = @_;

    my $project;
    my $guard = $self->txn_scope();
    eval {
        my $repos = delete $args->{repos};
        $args->{id} ||= Cirque::Util::random_uuid( $self, $args );
        $project = $self->$next($args);
        foreach my $repo (@$repos) {
            $self->add_repository( {
                project_id => $project->id,
                %$repo,
            } );
        }
        $self->add_milestone( {
            project_id => $project->id,
            name       => 'Not defined',
        } );
        $guard->commit;
    };
    # XXX Should we do something like $guard->rollback($@) if $@ ?
    if (my $e = $@) {
        eval { $guard->rollback };
        Carp::croak($e);
    }
    return $project ? $project : ();
};

sub all {
    my ($self) = @_;
    $self->get_handle('DB::Slaves')->search( $self->table );
}

sub add_repository {
    my ($self, $params) = @_;
    $self->get('API::Repository')->create( $params );
}

sub remove_repository {
    my ($self, $params) = @_;
    my $project_id = $params->{project_id};
    my $repo_id    = $params->{repository_id};

    $self->get('API::Repository')->delete( {
        project_id => $project_id,
        id => $repo_id
    } );
}

sub add_milestone {
    my ($self, $params) = @_;
    $self->get('API::Milestone')->create( $params );
}

sub load_milestones {
    my ($self, $project_id) = @_;
    return $self->get('API::Milestone')->search(
        {
            project_id => $project_id,
        },
        {
            order_by => 'due_on DESC',
        }
    );
}

sub find_milestone {
    my ($self, $args) = @_;
    my ($milestone) = $self->get('API::Milestone')->search( {
        id => $args->{ milestone_id },
        project_id => $args->{ project_id },
    } );
    return $milestone;
}

sub add_member {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Master');
    my $author = delete $args->{author};
    my $id = Cirque::Util::random_uuid( $self, $args );
    my $row = $handle->insert( 'cirque_project_member' => { id => $id, %$args, } );
    return $row;
}

sub remove_member {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Master');
    my $author = delete $args->{author};
    $handle->delete( 'cirque_project_member' => { %$args } );
}

sub load_members {
    my ($self, $project_id) = @_;
    my $handle = $self->get_handle('DB::Master');
    return $handle->search( 'cirque_project_member' => { project_id => $project_id } );
}

sub load_member_projects {
    my ($self, $account_id) = @_;

    my $handle = $self->get_handle('DB::Master');
    return $handle->search_by_sql(<<EOSQL, [ $account_id ], 'cirque_project')
        SELECT p.*
            FROM cirque_project p JOIN cirque_project_member m ON m.project_id = p.id
            WHERE m.account_id = ?
EOSQL
}

no Mouse;

1;
