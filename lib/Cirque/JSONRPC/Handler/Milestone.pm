package Cirque::JSONRPC::Handler::Milestone;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

sub load_for_project {
    my ($self, $params, $procedure, $c) = @_;

    return {
        milestones => [
            map { $_->get_columns } $c->get('API::Milestone')->search( { project_id => $params->{project_id} } )
        ]
    }
}

no Mouse;

1;

__END__