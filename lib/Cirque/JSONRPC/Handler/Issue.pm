package Cirque::JSONRPC::Handler::Issue;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

sub preview {
    my ($self, $params, $procedure, $c) = @_;

    my $project = $c->get('API::Project')->find( $params->{project_id} );
    if ( $project ) {
        $params->{description} =
            $c->get('API::Issue')->fixup_gitlink( $project, $params->{description} );
    }

    return $params;
}

around fetch => sub {
    my ( $next, $self, $params, $procedure, $c ) = @_;
    my $h = $self->$next($params, $procedure, $c);

    # XXX This is not efficient :/ combine this in 1 sql statement
    my $relation_api = $c->get('API::IssueRelation');
    my $issue_api = $c->get('API::Issue');
    my @parents = map { $issue_api->find( $_->parent_issue_id ) } $relation_api->search( { issue_id => $h->{id} } );
    my @children = map { $issue_api->find( $_->issue_id ) } $relation_api->search( { parent_issue_id => $h->{id} } );
	
    $h->{children} = [ map { $_->get_columns } @children ];
    $h->{parents}  = [ map { $_->get_columns } @parents ];

    return $h;
};

sub set_subissues {
    my ( $self, $params, $procedure, $c ) = @_;
    my $issue_api = $c->get( 'API::Issue' );
    $issue_api->set_subissues( $params->{author}, $params->{issue_id}, @{$params->{subissues}} );
    return;
}

no Mouse;

1;

__END__
