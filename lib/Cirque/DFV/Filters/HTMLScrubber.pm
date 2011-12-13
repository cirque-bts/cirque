package Cirque::DFV::Filters::HTMLScrubber;

use warnings;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $SCRUBBER );
use HTML::Scrubber;

BEGIN {
    require Exporter;
    $VERSION = '0.02';
    @ISA = qw( Exporter );
    @EXPORT = qw();
    %EXPORT_TAGS = (
        'all' => [ qw( html_scrub ) ]
    );
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
    $SCRUBBER = HTML::Scrubber->new;
}

sub html_scrub {
    my %args = @_;
    return sub { return _html_scrub( shift, %args ) };
}

sub _html_scrub {
    my ($value,%args) = @_;
    _reset_scrubber();
    for ( qw/ comment process script style allow deny rules default / ) {
        next unless defined $args{$_};
        my @val = ref $args{$_} eq 'HASH' ? ( %{ $args{$_} } ) :
                  ref $args{$_} eq 'ARRAY' ? ( @{ $args{$_} } ) :
                  $args{$_}
        ;
        $SCRUBBER->$_( @val );
    }
    return $SCRUBBER->scrub($value);
}

sub _reset_scrubber {
    $SCRUBBER->{ $_ } = 0 for qw/ _style _script _comment _process /;
    $SCRUBBER->{ _rules } = { '*' => 0 };
    $SCRUBBER->{ _optimize } = 1;
    $SCRUBBER->{ _r } = '';
}

1;
