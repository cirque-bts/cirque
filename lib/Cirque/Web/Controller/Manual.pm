package Cirque::Web::Controller::Manual;
use Cirque::Pragmas;
use Mouse;
use File::Spec;

extends 'Cirque::Web::Controller';

sub list {
    my ( $self, $c ) = @_;

    my $stash = $c->stash;

    my $mandir = File::Spec->catfile( $c->home, qw/ misc manual / );
    my $pattern = File::Spec->catfile( $mandir, qw/ *.tx/ );
    my @files =
        map { s/\.tx$//; s/^$mandir\///; $_ }
        glob $pattern
    ;

    $stash->{files} = [ @files ];
}

sub view {
    my ( $self, $c ) = @_;

    my $match = $c->match;
    my $stash = $c->stash;

    my $manfile = File::Spec->catfile( $c->home, qw/ misc manual /, $match->{name}. '.tx' );
    my $manual;

    open my $fh, '<', $manfile;
    if ( $fh ) {
        $manual = join "", <$fh>;
        close $fh;
    }

    $stash->{manual_title} = $match->{name};
    $stash->{manual} = $manual;
}

no Mouse;

1;
__END__

