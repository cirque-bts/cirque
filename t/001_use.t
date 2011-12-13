use strict;
use Test::More;
use File::Find;

my @files;
find({
    no_chdir => 1,
    wanted => sub {
        my $file = $File::Find::name;
        if (-f $file && $file =~ s/\.pm$// ) {
            $file =~ s{^lib\/}{};
            $file =~ s{/}{::}g;
            push @files, $file;
        }
    }
}, "lib");

ok @files;
use_ok $_ for @files;


done_testing;
