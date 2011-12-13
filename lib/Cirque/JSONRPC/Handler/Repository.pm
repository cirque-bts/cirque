package Cirque::JSONRPC::Handler::Repository;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

sub list {
    my ( $self, $params, $procedure, $c ) = @_;
    my $repo_api = $c->get('API::Repository');
    my $repos = $repo_api->load_by_project( $params->{project_id} ) || [];
    return { repositories => [ map { $_->get_columns } @$repos ] };
}

sub branches {
    my ( $self, $params, $procedure, $c ) = @_;
    my $repo_api = $c->get('API::Repository');
    my @branches = $repo_api->load_branches( { repository_id => $params->{ id } } );
    return { branches => [ map { $_->get_columns } @branches ] };
}

no Mouse;

1;

__END__
