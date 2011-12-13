use strict;
use Test::More;

use_ok "Cirque::Container";

subtest 'basic' => sub {
    my $c = Cirque::Container->new;
    ok $c;
};

subtest 'scoped components' => sub {
    my $c = Cirque::Container->new;
    ok $c;

    my $hook_called = 0;
    my $key = join '.', time(), rand(), {};

    $c->register( 'Scoped' => sub {
        return { key => $key, count => $hook_called++ };
    }, { scoped => 1 });

    for my $i ( 0..1) {
        my $guard = $c->new_scope();
        my $h = $c->get('Scoped');
        if (! ok $h, "Got something back") {
            diag explain $h;
        } else {
            is $h->{key}, $key, "key matches";
            is $h->{count}, $i, "count matches";
        }
    };
};

done_testing;