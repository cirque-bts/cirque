use strict;
use utf8;
use IO::Handle;
use Test::More;
use Encode;
use URI;

use_ok "Cirque::WAF::Request";

# Instantiate Cirque::WAF::Request
# Give it an UTF-8 encoded parameter list for both POST and GET
# Make sure that query_parameters and body_parameters are all decoded
subtest 'Query string UTF8 check' => sub {
    my $value = "日本語テスト";
    my $uri = URI->new( "http://example.com/foo?query=" . encode_utf8($value) );
    my $req = Cirque::WAF::Request->new( {
        QUERY_STRING => $uri->query
    } );

    is $req->param('query'), $value;
};

subtest 'POST UTF8 check' => sub {
    my $value = "日本語テスト";
    my $uri = URI->new( "http://example.com/foo?query=" . encode_utf8($value) );
    my $body = $uri->query;
    open my $input, '<', \$body or die;
    my $req = Cirque::WAF::Request->new( {
        CONTENT_LENGTH => length $body,
        CONTENT_TYPE   => "application/x-www-form-urlencoded",
        'psgi.input' => $input
    } );

    is $req->param('query'), $value;
};

done_testing;