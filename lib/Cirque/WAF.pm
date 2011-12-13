package Cirque::WAF;
use Cirque::Pragmas;
use Mouse;
use Cirque::Container;
use Cirque::Context;
use Cirque::WAF::Context;
use Cirque::WAF::Request;
use Cirque::WAF::Response;
use Plack::Request;
use Router::Simple;
use Try::Tiny;


has appname => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $klass = blessed $self;
        $klass =~ s/^Cirque:://;
        return $klass;
    }
);
        
has context => (
    is => 'ro',
    isa => 'Cirque::WAF::Context',
    handles => [ qw(container config) ]
);

has components => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
);

has default_view_class => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 'Xslate',
);

has router => (
    is => 'ro',
    isa => 'Router::Simple',
    required => 1,
);

has use_reverse_proxy => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub bootstrap {
    my $class = shift;
    my $ctxt  = Cirque::WAF::Context->bootstrap(@_);

    my $appname = $class;
    $appname =~ s/^Cirque:://;

    my $router = $ctxt->get( $appname . '::Router' );
    my $use_reverse_proxy = 
        # if USE_REVERSE_PROXY exists, use that value
        exists $ENV{USE_REVERSE_PROXY} ?  $ENV{USE_REVERSE_PROXY} :
        # if PLACK_ENV is production, then use reverse proxy
        $ENV{PLACK_ENV} eq 'production' ? 1 :
        # otherwise no
        0
    ;
    my $self  = $class->new(
        appname           => $appname,
        context           => $ctxt,
        use_reverse_proxy => $use_reverse_proxy,
        router            => $router,
    );

    $self->register_ctxt($ctxt);
    
    $ctxt->search_plugins;

    return $self;
}

sub register_ctxt {
    my ($self, $ctxt) = @_;
    my $copy = $self;
    Scalar::Util::weaken($copy);

    $ctxt->container->register( $self->appname => $copy );
    return $self;
}


sub to_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;
        my $res =  $self->handle_psgi( $env );
        return $res;
    };
    if ($self->use_reverse_proxy) {
        require Plack::Middleware::ReverseProxy;
        $app = Plack::Middleware::ReverseProxy->wrap( $app );
    }
    return $app;
}

sub handle_psgi {
    my ($self, $env) = @_;

    my $context = $self->context;
    my $guard   = $context->new_request( $env );

    try {
        $self->dispatch( $context, $env );
    } catch {
        my $e = $_;
        if ($e !~ /cirque\.abort/) {
            warn $e; # FIXME
            $self->handle_server_error( $context, $e );
        }
    };

    return $context->response->finalize();
}

sub get_component {
    my ($self, $klass, $prefix) = @_;

    if ( $klass !~ s/^\+// ) {
        if (! $prefix) { Carp::croak( "No prefix provided" ) }
        $klass = join '::', $prefix, $klass;
    }

    Mouse::Util::load_class($klass) unless
        Mouse::Util::is_class_loaded($klass);

    my $component = $self->components->{$klass};
    if (! $component) {
        my $key = $klass;
        $key =~ s/^Cirque:://;
        my $config = $self->config->{$key} || {};
        $self->components->{$klass} = 
            $component = $klass->new( %$config, app => $self);
    }

    return $component;
}

sub get_controller {
    my ($self, $klass) = @_;
    $self->get_component( $klass, ref($self).'::Controller' );
}

sub dispatch {
    my ($self, $context, $env) = @_;

    my $h = $self->router->match( $env );
    if (! $h) {
        # 404
        $self->handle_not_found( $context, $env );
        return;
    }

    $context->match( $h );
    my $action = $h->{action};
    my $controller_class = $h->{controller};
    my $controller = $self->get_controller( $controller_class );

    $controller->execute( $action, $context );
    if (! $context->finished) {
        $self->render( $context, $controller, $action );
    }
}

sub render {
    my ($self, $context, $controller, $action) = @_;
 
    $controller ||= $self->get_controller( $context->match->{controller} );
    $action ||= $context->match->{action};

    unless ( $controller->isa( 'Cirque::WAF::Controller' ) ) {
        $controller = $self->get_controller( $controller );
    }

    my $template = $context->stash->{template} ||
        join( '/', do {
            my @list = ($action);
            unshift @list, $controller->namespace if $controller->namespace;
            @list
        } )
    ;

    my $view_class = $context->stash->{view_class} ||
        $controller->view_class ||
        $self->default_view_class
    ;
    my $appname = $self->appname;
    my $view = $self->get_component( $view_class, "Cirque::$appname\::View" );
    if (! $view) {
        die "No view found";
    }
    $view->process( $context, $template );
}

sub handle_not_found {
    my ($self, $context, $env) = @_;

    my $response = $context->response;
    $response->code( 404 );
    $response->content_type( "text/plain" );
    $response->body( "File Not Found" );
}

sub handle_server_error {
    my ($self, $context, $message ) = @_;
    my $stash = $context->stash;
    my $res = $context->response;
    $stash->{message} = $message || 'Internal Server Error';
    $stash->{code} = 500;
    my $controller = $self->get_component( 'Root', ref($self).'::Controller' );
    $res->body( $self->render( $context, $controller, 'error' ) );
    $res->code( 500 );
    $context->finished( 1 );
}

no Mouse;

1;
