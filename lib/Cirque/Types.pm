package Cirque::Types;
use strict;
use warnings;
use Mouse::Util::TypeConstraints;

subtype 'PositiveInt'
    => as 'Int'
    => where { $_ > 0 }
;

no Mouse::Util::TypeConstraints;

1;
