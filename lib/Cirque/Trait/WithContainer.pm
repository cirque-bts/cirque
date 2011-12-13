package Cirque::Trait::WithContainer;
use Mouse::Role;

has container => (
    is => 'ro',
    isa => 'Cirque::Container',
    required => 1,
);

sub get {
    my ($self, @args) = @_;
    $self->container->get(@args);
}

no Mouse::Role;

1;
