package Cirque::Pragmas;
use 5.10.0;
use strict;
use utf8;
use feature ();
use warnings;

sub import {
    utf8->import;
    strict->import();
    feature->import( qw(say state) );
    warnings->unimport;
    warnings->import(
        FATAL => qw(
            closed threads internal debugging pack
            portable prototype inplace io pipe unpack malloc
            deprecated glob digit printf layer
            reserved taint closure semicolon
        )
    );
    warnings->unimport( qw(exec newline unopened) );
}

1;
