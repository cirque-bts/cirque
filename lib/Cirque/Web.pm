package Cirque::Web;
use Cirque::Pragmas;
use Mouse;
use Plack::Middleware::Session;
use HTML::FillInForm;

extends 'Cirque::WAF';

has session_store => (
    is => 'ro',
);

around to_app => \&_build_app;
sub _build_app {
    my ($next, $self) = @_;

    my $app = $self->$next;
    my $ctxt = $self->context;

    if ( my $store = $self->session_store ) {
        $app = Plack::Middleware::Session->wrap( $app, store => $app );
    } else {
        require Plack::Session::State::Cookie;
        require Plack::Session::Store::DBI;
        $app = Plack::Middleware::Session->wrap( $app,
            state => Plack::Session::State::Cookie->new(
                session_key => 'cique_session',
                httponly    => 1,
                path        => "/",
                expires     => 86400,
            ),
            store => $ctxt->get('Session::Store'), 
        );
    }
    if ( $ENV{PLACK_ENV} eq 'development' ) {
        require Plack::Middleware::Static;
        require Plack::Middleware::Proxy::RewriteLocation;
        require Plack::App::Proxy;
        require Plack::App::URLMap;

        $app = Plack::Middleware::Static->wrap( $app, 
            path => sub { s{^/static/}{} },
            root => $ctxt->path_to( "htdocs" )
        );

        my $proxy_app = Plack::App::Proxy->new(
            remote => sprintf(
                'http://%s/attachment/view',
                $ENV{ CIRQUE_RPC_URL } || '127.0.0.1:8080',
            ),
            preserve_host_header => 1,
        )->to_app;
        $proxy_app = Plack::Middleware::Proxy::RewriteLocation->wrap($proxy_app);

        my $urlmap = Plack::App::URLMap->new;
        $urlmap->map( '/attachment/view' => $proxy_app );
        $urlmap->map( '/'                => $app );
        $app = $urlmap->to_app;
    }
    return $app;
};

after render => \&_fillform;
sub _fillform {
    my ($self, $context) = @_;

    my $fdat = $context->stash->{fdat};

    # nothing to fill in
    return unless $fdat;

    my $res = $context->response;
    if ( $res->content_type !~ m{^text/x?html}i ) {
        # it ain't no html
        return;
    }

    my $body = $res->body;
    $res->body( HTML::FillInForm->fill( \$body, $fdat ) );
};

no Mouse;

1;
