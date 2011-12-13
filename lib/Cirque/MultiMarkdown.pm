package Cirque::MultiMarkdown;
use strict;
use parent qw/ Text::MultiMarkdown /;
use HTML::Scrubber;

our $ALLOWED_TAGS = [qw[
    a b br code div h1 h2 h3 h4 h5 h6 hr i img li ol p pre strong ul
]];

our $RULES = {
    a => { '*' => 1 },
    img => { '*' => 1 },
};

sub new {
    my ( $class, @params ) = @_;
    my $self = $class->SUPER::new( @params );
    return $self;
}

sub scrubber { 
    my $self = shift;
    my $scrubber = $self->{ scrubber };
    if ( ! $scrubber ) {
        $scrubber = $self->{ scrubber } = HTML::Scrubber->new( allow => $ALLOWED_TAGS );
        $scrubber->rules( %$RULES );
    }
    return $scrubber;
}

sub markdown {
    my ( $self, $text, $options ) = ref $_[0] eq __PACKAGE__ ? @_ : ( __PACKAGE__->new, @_ );
    my $markdown = $self->SUPER::markdown( $text, $options );
    return $self->scrubber->scrub( $markdown );
}

1;

__END__

