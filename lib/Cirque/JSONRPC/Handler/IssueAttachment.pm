package Cirque::JSONRPC::Handler::IssueAttachment;
use Cirque::Pragmas;
use Mouse;
use MIME::Base64 ();

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

override create => sub {
    my ( $self, $params, $procedure, $c ) = @_;

    my $issue_api = $c->get('API::Issue');

    my $res = $c->get('Validator')->check( $params, "create_issue_attachment" );
    if ( ! $res->success ) {
        die( $self->create_validation_error_message( $res ) );
    }

    my $issue = $issue_api->find( delete $params->{issue_id} ) or die( "Conld not find associated issue\n" );
    $params = $res->valid;
    $params->{encode} ||= 'Base64';

    my $attach = $issue_api->add_file( $issue->id => $params ) or die( "Failed to attach\n" );
    return { id => $attach->id };
};

around fetch => sub {
    my ( $next, $self, $params, $procedure, $c ) = @_;
    my $attachment = $self->$next( $params, $procedure, $c );
    $attachment->{body} = MIME::Base64::encode_base64($attachment->{body});
    return $attachment;
};

override delete => sub {
    my ( $self, $params, $procedure, $c ) = @_;
    my $issue_api = $c->get('API::Issue');
    my $attach_api = $c->get('API::IssueAttachment');
    my $attachment = $attach_api->find( $params->{id} ) or die( "Could not find such attachment\n" );

    my $issue_id = $attachment->issue_id;
    $params->{attach_id} = delete $params->{id};

    $issue_api->remove_file( $issue_id => $params );
    return;
};

sub list {
    my ( $self, $params, $procedure, $c ) = @_;
    my $issue_api = $c->get('API::Issue');
    my $issue = $issue_api->find( $params->{issue_id} ) or die( "Could not find associated issue\n" );
    my @attachments = $issue_api->load_files( { issue_id => $issue->id } );
    for my $attachment ( @attachments ) {
        $attachment = $attachment->get_columns;
        delete $attachment->{body};
    }
    return { attachments => [ @attachments ] };
}

no Mouse;

1;

__END__
