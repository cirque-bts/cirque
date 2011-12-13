package Cirque::Container::Declare;
use strict;
use parent qw(Exporter);
use Cirque::Container;

our @EXPORT = qw(
    container
    register
);

sub register ($$;$);
sub container (&) {
    my $code = shift;

    my $container = Cirque::Container->new;
    local *register = sub { $container->register(@_) };
    $code->();
    return $container;
}

1;
