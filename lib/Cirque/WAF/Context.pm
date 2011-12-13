package Cirque::WAF::Context;
use Cirque::Pragmas;
use Mouse;
use Cirque::WAF::Request;
use Encode ();
use JSON ();
use Scope::Guard ();

extends 'Cirque::Context';

has finished => (
    is => 'rw',
    isa => 'Bool',
);

has request => (
    is => 'rw',
);

has response => (
    is => 'rw',
);

has stash => (
    is => 'rw',
);

has match => (
    is => 'rw',
);

sub new_request {
    my ($self, $env) = @_;
    my $request = Cirque::WAF::Request->new($env);
    $self->stash( {} );
    $self->finished( 0 );
    $self->request( $request );
    $self->response( $request->new_response( 200 ) );

    my $container_guard = $self->container->new_scope();
    return Scope::Guard->new(sub {
        undef $container_guard;
        $self->request( undef );
        $self->response( undef );
        $self->stash( undef );
        $self->match( undef );
    } );
}

sub redirect {
    my ( $self, $url ) = @_;
    $self->response->status(302);
    $self->response->header( Location => $url );
    $self->abort(1);
}

sub render_json {
    my ($self, $data) = @_;
    
    $self->response->status(200);
    $self->response->content_type("application/json");
    $self->response->body(Encode::decode_utf8(JSON::encode_json($data)));
    $self->finished(1);
}

sub abort {
    die "cirque.abort";
}

no Mouse;

1;
