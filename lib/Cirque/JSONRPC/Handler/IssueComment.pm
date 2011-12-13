package Cirque::JSONRPC::Handler::IssueComment;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

sub preview {
    my ($self, $params, $procedure, $c) = @_;

    unless ( $params->{project_id} ) {
        my $issue = $c->get('API::Issue')->find( $params->{issue_id} );
        $params->{project_id} = $issue->project_id;
    }

    my $project = $c->get('API::Project')->find( $params->{project_id} );
    if ( $project ) {
        $params->{body} =
            $c->get('API::IssueComment')->fixup_gitlink( $project, $params->{body} );
    }

    return $params;
}

sub list {
    my ( $self, $params, $procedure, $c ) = @_;
    my $issue_api = $c->get('API::Issue');
    my $res = $c->get('Validator')->check( $params, 'issue_comments' );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }
    my @comments = $issue_api->load_comments( scalar $res->valid );
    for my $comment ( @comments ) {
        $comment = $comment->get_columns;
    }
    return { comments => [ @comments ] };
}

override 'create' => sub {
    my ( $self, $params, $procedure, $c ) = @_;

    my $issue_api = $c->get('API::Issue');
    my $proj_api = $c->get('API::Project');
    my $issue = $issue_api->find( $params->{issue_id} ) or die( "Could not find associated issue\n" );
    my $proj = $proj_api->find( $issue->project_id ) or die( "Could not find associated project\n" );

    $params->{project_id} = $proj->id;

    my $res = $c->get('Validator')->check( $params, 'create_issue_comment' );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }

    $params = scalar $res->valid;
    my $issue_id = delete $params->{issue_id};

    my $comment = $issue_api->add_comment( $issue_id => $params ) or die( "Could not add comment\n" );
    return { id => $comment->id };
};

no Mouse;

1;

__END__
