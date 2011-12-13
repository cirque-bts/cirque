package Cirque::WAF::Response;
use Cirque::Pragmas;
use Mouse;
use MouseX::Foreign qw(Plack::Response);
use Data::Recursive::Encode;

sub new_from_plack_res {
    my ($class, $res) = @_;
    bless $res, $class;
}

around finalize => sub {
    my ($next, $self, @args) = @_;
    my $psgi = $self->$next(@args);

    if (ref $psgi eq 'ARRAY' ) {
        $psgi = Data::Recursive::Encode->encode_utf8($psgi);
    }
    return $psgi;
};

no Mouse;

1;