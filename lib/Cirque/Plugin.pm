package Cirque::Plugin;
use Mouse;

has name => (
    is => 'ro',
    required => 1,
);
    
has plugin_dir => (
    is => 'ro',
    required => 1,
    default => sub { $ENV{PLUGIN_DIR} }
);

has callbacks => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

sub BUILDARGS {
    my ($self, %args) = @_;

    foreach my $cb_key ( grep { /^on_/ } keys %args ) {
        if ( my $cb = delete $args{$cb_key} ) {
            my $key = $cb_key;
            $key =~ s/^on_//;
            $args{callbacks}->{$key} = $cb;
        }
    }
    return \%args;
}

sub get_routes_file {
    my ($self, $ctxt, $component) = @_;

    if ($component eq 'Web') {
        return ( File::Spec->catdir( $self->plugin_dir, 'routes.pl' ) );
    } elsif ( $component eq 'JSONRPC' ) {
        return ( File::Spec->catdir( $self->plugin_dir, 'rpc_routes.pl' ) );
    } else {
        return ();
    }
}
sub get_jsonrpc_routes_file {
}

sub add_routes {
    my ($self, $ctxt, $component, $file) = @_;

    my $router = require $file;

    # XXX - HACK. eeeewwww....
    $component->router->{routes} = [
        @{$component->router->{routes}},
        @{$router->{routes}}, 
    ];
}

sub get_view_dirs {
    my ($self, $ctxt, $component) = @_;
    return (File::Spec->catdir( $self->plugin_dir, "view" ));
}

sub get_config_file {
    my ($self, $ctxt) = @_;
    my @files = ( File::Spec->catfile( $self->plugin_dir, 'etc', 'config.pl' ) );
    if ( $ENV{DEPLOY_ENV} ) {
        my $file = sprintf File::Spec->catfile( $self->plugin_dir, 'etc', 'config_%s.pl' ), $ENV{DEPLOY_ENV};
        push @files, $file if -f $file;
    }
    return @files;
}

sub get_container_file {
    my ( $self ) = @_;
    File::Spec->catfile( $self->plugin_dir, 'etc', 'container.pl' );
}

sub add_config {
    my ($self, $ctxt, $file) = @_;
    my $config = require $file;
    next unless $config;
    $ctxt->container->{objects}->{config} = { %{$ctxt->container->{objects}->{config}}, %$config };
}

sub merge_container {
    my ($self, $ctxt, $container) = @_;
    for my $key ( %{ $container->registry } ) {
        $ctxt->container->register( "$key" => $container->registry->{"$key"} );
    }
}

sub register {
    my ($self, $ctxt) = @_;

    eval { $self->callbacks->{register}->( $ctxt ) };
    Carp::confess $@ if $@;

    foreach my $name ( qw( Web JSONRPC ) ) {
        my $component = eval { $ctxt->get($name) };
        if (! $component) {
            return;
        }

        foreach my $file ( $self->get_config_file( $ctxt ) ) {
            if ( -f $file ) {
                $self->add_config( $ctxt, $file );
            }
        }

        foreach my $file ( $self->get_container_file ) {
            next unless -f $file;
            my $container = require $file;
            next unless $container;
            $self->merge_container( $ctxt, $container );
        }

        # automatically add routes
        foreach my $file ( $self->get_routes_file($ctxt, $name) ) {
            if ( -f $file ) {
                $self->add_routes( $ctxt, $component, $file );
            }
        }

        # auto include view directories
        next if $name ne 'Web';

        foreach my $dir ( $self->get_view_dirs($ctxt, $name) ) {
            if ( -e $dir ) {
                $component->get_component('+Cirque::Web::View::Xslate')->add_path( $dir );
            }
        }
    }

    return $self;
}

no Mouse;

1;

__END__

=head1 NAME

Cirque::Plugin - Plugin Object

=head1 FILES

=head2 init.pl (Required)

Initialization script. Create a Cirque::Plugin object and return it.

    # minimal init.pl
    return Cirque::Plugin->new(
        name => "Hello, World"
    );

You can create directories, setup stuff, whatever.

The Cirque::Plugin object can install hooks to be called at registration time:

    Cirque::Plugin->new(
        new => "Hello World",
        on_register => sub {
            my ($plugin, $ctxt) = @_;
        }
    );

The on_register callback will receive a Cirque::Context (or its subclass) object that you can do bunch of things with.

=head2 routes.pl

Create a Router::Simple instance to map your controllers.

=head2 lib/*

Put your libraries here.

=head2 view/*

Put your templates here.

=head1 HELLO WORLD SAMPLE

You can check out our hello world sample:

    ln -s `pwd`/samples/plugins/hellowrold plugins/
    # start cirque

=cut
