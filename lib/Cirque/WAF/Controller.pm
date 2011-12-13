package Cirque::WAF::Controller;
use Cirque::Pragmas;
use Mouse;

has app => (
    is       => 'ro',
    isa      => 'Cirque::WAF',
    required => 1,
);

has namespace => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has view_class => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_view_class {
    my $self = shift;
    $self->app->default_view_class;
}

sub _build_namespace {
    my $self = shift;
    my $pkg = blessed $self;
    $pkg =~ s/^Cirque::.+::Controller:://;
    $pkg =~ s/::/\//g;
    lc $pkg;
}

sub execute {
    my ($self, $action, $c) = @_;
    $self->$action( $c );
}

sub NOT_FOUND {
    my ($self, $c) = @_;

    my $res = $c->response;
    $res->status(404);
    $res->content_type( 'text/plain' );
    $res->body( "Not Found" );
    $c->finished(1);
    return $res;
}

no Mouse;

1;
