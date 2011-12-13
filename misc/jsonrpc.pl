use strict;
use utf8;
use Data::Dumper::Concise;
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;
use JSON;
use File::Spec;
use Encode;

my $coder = JSON->new->utf8(1)->pretty(1)->canonical(1);
my $specs = require File::Spec->catfile( qw/ misc jsonrpc_specs.pl / );

# default spec => { isa => "Str", required => 1 }
my @procedures = map {
    my $proc = $_;
    my $params = $proc->{params};

    while ( my ($k, $v) = each %$params ) {
        $v->{isa} ||= 'Str';
        if (! exists $v->{required} ) {
            $v->{required} = 1;
        }
    }

    $proc->{request} = {
        jsonrpc => "2.0",
        id => "...",
        params => {
            map { ($_ => "...") } keys %$params
        }
    };

    $proc->{response} = {
        jsonrpc => "2.0",
        id => "...",
        result => {
            map { ($_ => "...") } keys %{$proc->{result}}
        }
    };

    $proc;
} @$specs;

my $template = $ENV{MODE} ? $ENV{MODE} : 'pod';

my %args = (
    syntax => "TTerse",
    type   => $ENV{TYPE} ? $ENV{TYPE} : 'text',
    module => [ "Text::Xslate::Bridge::TT2Like", "Data::Dumper::Concise" ],
    function => {
        demo => sub {
            my $json = $coder->encode(@_);
            join "\n", map { "    $_" } split /\n/, $json
        }
    },
);

my $xslate = Text::Xslate->new( %args );

open my $fh, '<', File::Spec->catfile( qw/ misc jsonrpc_tx /,  "$template.tx" ) or die "No such file $template.tx";
my $txdata = join "", <$fh>;
close $fh;
$txdata = Encode::decode( 'utf8', $txdata );

my $str = $xslate->render_string( $txdata, { procedures => \@procedures } );

print $str;
