package Cirque::Web::Controller::Attachment;
use Cirque::Pragmas;
use Mouse;
use MIME::Base64 ();

extends 'Cirque::Web::Controller';

sub view {
    my ( $self, $c ) = @_;

    my $res = $c->response;
    my $match = $c->match;
    my $api = $c->get('API::RPC');
    my $file = $api->issue_attachment_fetch({ id => $match->{ attach_id } });

    Carp::croak("Specified file dosen't exist") unless $file;

    $res->content_type( $file->{mimetype} );
    $res->content_length( $file->{filesize} );

    # use fh style body with binmode on to avoid encoding issues
    my $body = MIME::Base64::decode_base64( $file->{body} );
    open my $fh, '<', \$body;
    binmode $fh;

    $res->body( $fh );
    $c->finished( 1 );
}

sub remove {
    my ($self, $c) = @_;

    my $match = $c->match;
    my $member = $self->assert_login( $c );

    my $api = $c->get('API::RPC');
    my $attach = $api->issue_attachment_fetch( { id => $match->{attach_id} } );
    my $issue = $api->issue_fetch( { id => $attach->{issue_id} } );

    $api->issue_attachment_delete( { 
        id         => $match->{attach_id},
        author     => $member->{author},
    } );

    $c->redirect( "/issue/" . $issue->{id} );
}

no Mouse;

1;
__END__

