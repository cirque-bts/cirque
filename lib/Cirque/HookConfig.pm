package Cirque::HookConfig;

use strict;
use warnings;
use Exporter 'import';
use Carp ();

sub load {
    my ( $file ) = @_;
    my $config = do $file || Carp::croak( "could not load hook-config $file" );
    my $env = $ENV{'DEPLOY_ENV'} || 'default';
    return $config->{$env};
}

sub config_file {
    my ( $name ) = @_;
    return sprintf( '%s/etc/hook_config/%s.pl', $ENV{'DEPLOY_HOME'}, $name );
}

1;
