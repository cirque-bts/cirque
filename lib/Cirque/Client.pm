package Cirque::Client;
use strict;
use JSON ();
use Encode ();
use Furl::HTTP;
use HTTP::Status ();
use Class::Accessor::Lite
    rw => [ qw(
        url
        furl
        coder
        api_key
        api_secret
    ) ]
;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $res = bless {
        url   => $ENV{CIRQUE_RPC_URL} || $ENV{CIRQUE_JSONRPC_URL},
        coder => JSON->new->utf8(1),
        furl  => Furl::HTTP->new( agent => "Cirque::Client $VERSION" ),
        %args,
    }, $class;
    return $res;
}
        
sub jsonrpc {
    my ($self, $method, $params) = @_;

    my $coder = $self->coder;
    my $furl  = $self->furl;

    if (! $params->{'auth.api_key'} ) {
        if (my $api_key = $self->api_key) {
            $params->{'auth.api_key'} = $api_key;
        }
    }

    if (! $params->{'auth.api_secret'} ) {
        if (my $api_secret = $self->api_secret) {
            $params->{'auth.api_secret'} = $api_secret;
        }
    }

    my @hdrs = (
        "Content-Type" => "application/json",
        "X-Cirque-auth.api_key" => delete $params->{'auth.api_key'},
        "X-Cirque-auth.api_secret" => delete $params->{'auth.api_secret'},
    );
    my $content = $coder->encode({
        jsonrpc => "2.0",
        id      => join(".", time(), rand(), $$, {}),
        method  => $method,
        params  => $params,
    });

    my @res = $furl->post(
        $self->url,
        \@hdrs,
        $content
    );

    if (! HTTP::Status::is_success($res[1]) ) {
       Carp::croak( "HTTP Request failed: @res" );
    }

    return  $coder->decode( Encode::decode_utf8( $res[4] ) );
}


1;

__END__

=head1 NAME

Cirque::Client - Cirque Client 

=head1 SYNOPSIS

    use Cirque::Client;

    my $client =Cirque::Client->new();

    my $json = $client->jsonrpc(
        'issue.fetch' => {
            id => "id.of.issue",
        }
    );

=cut
