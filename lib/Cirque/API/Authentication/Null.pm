package Cirque::API::Authentication::Null;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::API::Authentication::External';

sub authenticate {
    my ($self, $args) = @_;
    my $member = {
        last_name    => undef,
        first_name   => undef,
        internal_id  => undef,
        account_id   => undef,
        email        => $args->{email},
        author       => $args->{email},
    };

    $self->initialize_member( $member );
    return $member;
}

no Mouse;

1;
