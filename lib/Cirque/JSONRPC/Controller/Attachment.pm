package Cirque::JSONRPC::Controller::Attachment;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Controller /;

sub view {
    my ( $self, $c ) = @_;

    my $res = $c->response;
    my $match = $c->match;
    my $attach_api = $c->get('API::IssueAttachment');
    my $file = $attach_api->find( $match->{ attachment_id } );

    unless ( $file ) {
       $res->body('Specified file does not exist.');
       $res->code('404');
       return $c->finished( 1 );
    }

    $res->content_type( $file->mimetype );
    $res->content_length( $file->filesize );

    # use fh style body with binmode on to avoid encoding issues
    my $body = $file->body;
    open my $fh, '<', \$body;
    binmode $fh;

    $res->body( $fh );
    $c->finished( 1 );
}

no Mouse;

1;
__END__

