package Cirque::WAF::Request;
use Cirque::Pragmas;
use Mouse;
use MouseX::Foreign qw(Plack::Request);
use Cirque::WAF::Response;
use Encode ();

has input_encoding => (
    is => 'ro',
    isa => 'Str',
    default => 'utf-8',
); 

around new_response => sub {
    my ($next, $self, @args) = @_;
    my $res = $self->$next(@args);
    Cirque::WAF::Response->new_from_plack_res($res);
};

around new => sub {
    my ($next, $class, @args) = @_;

    my $self = $class->$next(@args);
    my $ie = $self->input_encoding;
    _decode_hmv( $self->query_parameters, $ie );
    _decode_hmv( $self->body_parameters, $ie );
    delete $self->env->{'plack.request.merged'};
    $self;
};

sub _decode_hmv {
    my ($hmv, $ie) = @_;
    for my $key( $hmv->keys ) {
        my @values = map { Encode::decode($ie, $_) } $hmv->get_all( $key );
        $hmv->remove( $key );
        $hmv->add( $key => @values );
    }
}

no Mouse;

1;