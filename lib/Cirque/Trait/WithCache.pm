package Cirque::Trait::WithCache;
use Mouse::Role;
use Mouse::Util::TypeConstraints;

has cache => (
    is => 'ro',
    isa => duck_type( [ qw( get set delete ) ] ),
);

no Mouse::Role;
no Mouse::Util::TypeConstraints;

1;
