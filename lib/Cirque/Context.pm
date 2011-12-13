package Cirque::Context;
use Cirque::Pragmas;
use Mouse;
use Mouse::Util::TypeConstraints;
use Carp ();
use Cwd ();
use File::Basename ();
use File::Spec;
use Cirque::Container;
use Cirque::Plugin;
use Cirque::Util ();

has config_file => ( is => 'rw' );
has config => (
    is => 'rw',
    isa => 'HashRef',
);

has container_file => ( is => 'rw' );
has container => (
    is => 'rw',
    isa => duck_type( [ qw(get register) ] ),
    handles => [ qw(get) ]
);

sub bootstrap {
    my ($class, %args) = @_;
    my $self = $class->new();

    my $config_file = $self->filename_from_any(
        $args{config},
        $ENV{'CIRQUE_CONFIG'},
        $self->path_to('etc', 'config.pl' )
    );
    my $container_file = $self->filename_from_any(
        $args{container},
        $ENV{'CIRQUE_CONTAINER'},
        $self->path_to('etc', 'container.pl' )
    );
    $self->load_config( $config_file );
    $self->load_container( $container_file );
    $self->config_file( $config_file );
    $self->container_file( $container_file );
    return $self;
}

sub search_plugins {
    my ($ctxt) = @_;

    my $plugin_base = $ctxt->path_to( 'plugins' );
    foreach my $dir ( glob( File::Spec->catdir( $plugin_base, '*' ) ) ) {
        next unless -d $dir;

        $ctxt->add_plugin( $dir );
    }
}

sub add_plugin {
    my ($self, $dir) = @_;
    my $init_script = File::Spec->catfile( $dir, "init.pl" );
    return unless -f $init_script;

    # respect lib directories
    if ( my $libdir = File::Spec->catdir( $dir, "lib" )  ) {
        lib->import( $libdir );
    }

    # run initialization code
    local $ENV{ PLUGIN_DIR } = $dir;
    my $plugin = require $init_script;

    $plugin->register( $self );
}

sub filename_from_any {
    my ($self, @list) = @_;

    foreach my $file (@list) {
        next unless $file;

        if ( File::Spec->file_name_is_absolute( $file ) ) {
            return $file;
        } else {
            return $self->path_to($file);
        }
    }
    return ();
}

sub home {
    my $self = shift;
    return $self->{home} || $ENV{CIRQUE_HOME} || $ENV{DEPLOY_HOME} || Cwd::cwd()
}

sub path_to {
    my $self = shift;
    return File::Spec->catfile($self->home, @_);
}

sub load_config {
    my ($self, $file) = @_;

    my $result = {};
    foreach my $f (Cirque::Util::applyenv($file)) {
        next unless -f $f;
        my ($config) = $self->load_file(
            $f => (
                path_to => sub { $self->path_to(@_) },
                include => sub {
                    if (! defined wantarray ) {
                        Carp::croak("You called include() in void context! Did you remeber to do '+{ include \"file\", ... }' instead of '{ ... }' ?");
                    }
                    my $h = {};
                    foreach my $file (glob($_[0])) {
                        $h = Cirque::Util::merge_hashes( $h, $self->load_config($file) );
                    }
                    return wantarray ? %$h : $h;
                }
            )
        );
        $result = Cirque::Util::merge_hashes($result, $config);
    }
    $self->config( $result );
}

sub load_container {
    my ($self, $file) = @_;

    my $container = Cirque::Container->new;
    $container->register(config => $self->config);

    foreach my $f (Cirque::Util::applyenv($file)) {
        next unless -f $f;
        $self->load_file(
            $f => (
                register => sub (@) { $container->register(@_) }
            )
        );
    }
    $self->container($container);
}

sub load_file {
    my ($self, $file, %args) = @_;

    my $path = Cwd::abs_path($file);
    if (! $path) {
        Carp::croak("$file does not exist");
    }

    if (! -f $path) {
        Carp::confess("$path does not exist, or is not a file");
    }

    return if $INC{$path} && $self->{loaded_paths}{$path}++;
    delete $INC{$path};
    my $pkg = join '::',
        map { my $e = $_; $e =~ s/[\W]/_/g; $e }
        grep { length $_ } (
            'Cirque',
            'Context',
            File::Spec->splitdir(File::Basename::dirname($path)),
            File::Basename::basename($path)
        )
    ;

    {
        no strict 'refs';
        no warnings 'redefine';
        while ( my ($method, $code) = each %args ) {
            *{ "${pkg}::${method}" } = $code;
        }
    }

    my $code = sprintf <<'EOM', $pkg, $file;
        package %s;
        require '%s';
EOM
    my @ret = eval $code;
    die if $@;
    return @ret;
}

no Mouse;
no Mouse::Util::TypeConstraints;

1;

__END__

This class is the "global" context. DO NOT put webapp specific stuff in
this module
