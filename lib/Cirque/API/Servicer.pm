package Cirque::API::Servicer;
use Cirque::Pragmas;
use Mouse;
use String::Urandom; # Maybe replace with something else

with qw(Cirque::API::WithTeng);

around create => sub {
    my ($next, $self, $args) = @_;

    $args->{api_key} ||= String::Urandom->new(
        LENGTH => 12, 
        CHARS => [ 'a'..'z', 'A'..'Z', 0..9 ]
    )->rand_string;
    $args->{api_secret} ||= String::Urandom->new(
        LENGTH => 40, 
        CHARS => [ 'a'..'z', 'A'..'Z', 0..9 ]
    )->rand_string;
    $self->$next($args);
};

no Mouse;

1;