package Cirque::Web::View::Xslate;
use Cirque::Pragmas;
use Mouse;
use Text::Xslate;

has app => (
    is       => 'ro',
    isa      => 'Cirque::Web',
    required => 1,
);

has xslate => (
    is => 'rw',
    isa => 'Text::Xslate',
    lazy_build => 1,
    clearer => 'clear_xslate',
);

my $clearer = sub { $_[0]->clear_xslate };

has path => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    trigger => $clearer,
);

has cache_dir => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has cache => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    trigger => $clearer,
);

has function => (
    is => 'rw',
    isa => 'HashRef',
    trigger => $clearer,
);

has module => (
    is => 'rw',
    isa => 'ArrayRef',
    trigger => $clearer,
);

has input_layer => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has verbose => (
    is => 'rw',
    isa => 'Bool',
    trigger => $clearer,
);

has suffix => (
    is => 'rw',
    isa => 'Str',
    default => '.tx',
);

has syntax => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_syntax',
    trigger => $clearer,
);

has type => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has line_start => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has tag_start => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has tag_end => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has header => (
    is => 'rw',
    isa => 'ArrayRef',
    trigger => $clearer,
);

has footer => (
    is => 'rw',
    isa => 'ArrayRef',
    trigger => $clearer,
);

sub _build_xslate {
    my $self = shift;
    my %args = (
        path => $self->path,
        cache_dir => $self->cache_dir,
        cache => $self->cache,
    );

    foreach my $field ( qw(function module input_layer verbose suffix syntax type type line_start tag_start tag_end header footer ) ) {
        my $value = $self->$field;
        if ( defined $value ) {
            $args{ $field } = $value;
        }
    }

    Text::Xslate->new(%args);
}

sub add_path {
    my ($self, @paths) = @_;
    $self->path( [ @paths, @{ $self->path } ] );
}

sub process {
    my ($self, $context, $template) = @_;

    if ( ! $self->{localizer_init}++) {
        if ( my $loc = $context->get( "Localizer" ) ) {
            $self->clear_xslate(); # just in case

            my $function = $self->function;
            if (! $function) {
                $self->function( $function = {} );
            }
            $function->{loc} = sub { $loc->localize(@_) };
        }
    }

    my $content = $self->render( $template, $context->stash );
    my $response = $context->response;
    $response->content_type( "text/html" );
    $response->body( $content );
}

sub render {
    my ($self, $template, $vars) = @_;

    if (my $suffix = $self->suffix) {
        $template =~ s/(?<!$suffix)$/$suffix/;
    }

    $self->xslate->render( $template, $vars );
}

no Mouse;

1;
