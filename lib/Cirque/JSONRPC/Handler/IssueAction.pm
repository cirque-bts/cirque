package Cirque::JSONRPC::Handler::IssueAction;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

sub list {
    my ( $self, $params, $procedure, $c ) = @_;
    my $issue_api = $c->get('API::Issue');
    my $issue = $issue_api->find( $params->{issue_id} ) or die( "Could not find associated issue\n" );
    my @actions = $issue_api->load_actions( {issue_id => $params->{issue_id}} );
    return {
        actions => [
            map { $_->get_columns } @actions
        ]
    };
}

no Mouse;

1;

__END__
