package Cirque::JSONRPC::Handler::Project;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

override fetch => sub {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::Project');

    my $res = $c->get('Validator')->check( $params, "fetch_project" );
    my $proj;
    if (my $id = $res->valid('id')) {
        $proj = $api->find( $id );
    } elsif (my $slug = $res->valid('slug') ) {
        $proj = $api->find_by_slug( $slug );
    }

    if (! $proj ) {
        die "Could not find associated project";
    }

    my $data = $proj->get_columns;
    my $repo_api = $c->get('API::Repository');
    my $repos = $repo_api->load_by_project( $data->{id} );
    
    $data->{repositories} = [ map { $_->get_columns } @$repos ] if $repos;

    $data->{members} = [ map { $_->account_id } $api->load_members( $data->{id} ) ];

    return $data;
};

around delete => sub {
    my ( $next, $self, $params, $procedure, $c ) = @_;

    my $proj_api = $c->get('API::Project');
    my $issue_api = $c->get('API::Issue');
    my $res = $c->get('Validator')->check( $params, "delete_project" );

    my @issues = $issue_api->search( { project_id => $res->valid('id') } );
    for my $issue ( @issues ) {
        $issue_api->delete({ id => $issue->id });
    }

    $self->$next( $params, $procedure, $c );
};

sub find_by_slug {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::Project');
    my $proj = $api->find_by_slug( $params->{slug} ) or die "Could not find such project.\n";
    return $proj->get_columns;
}

sub list {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::Project');
    my @projects = map { $_->get_columns } $api->search({});
    for my $proj ( @projects ) {
        $proj->{members} = [ map { $_->account_id } $api->load_members( $proj->{id} ) ];
    }
    return { projects => \@projects };
}

sub member_add {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::Project');

    my $res = $c->get('Validator')->check( $params, "add_project_member" );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }
    
    my $project = $api->find( $res->valid('project_id') ) or die "Could not find such project.\n";
    $api->add_member( scalar $res->valid );
    return;
}

sub member_delete {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::Project');

    my $res = $c->get('Validator')->check( $params, "delete_project_member" );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }

    my $project = $api->find( $res->valid('project_id') ) or die "Could not find such project.\n";
    $api->remove_member( scalar $res->valid );
    return;
}

no Mouse;

1;

__END__
