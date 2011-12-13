package Cirque::API::Authentication::Simple;
use Cirque::Pragmas;
use Mouse;
use File::Spec;

extends 'Cirque::API::Authentication::External';

has members => ( is => 'ro', isa => 'HashRef', required => 1 );

sub authenticate {
    my ($self, $args) = @_;

    my $password = $self->members->{ $args->{email} };
    return unless defined $password;
    return unless $password eq $args->{password};

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
