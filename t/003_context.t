use strict;
use Test::More;

use_ok "Cirque::WAF::Context";
use_ok "Cirque::Container";

subtest 'scope' => sub {
    my $container = Cirque::Container->new;
    my $ctxt = Cirque::WAF::Context->new( container => $container );
    {
        my $guard = $ctxt->new_request({});
        isa_ok $ctxt->request, "Cirque::WAF::Request";
        isa_ok $ctxt->response, "Cirque::WAF::Response";
        isa_ok $ctxt->stash, "HASH";
        ok ! $ctxt->finished, "finished flag is off";
    }

    ok !$ctxt->request, "guard released, request is undefined";
    ok !$ctxt->response, "guard released, response is undefined";
    ok !$ctxt->stash, "guard released, stash is undefined";
};

subtest 'config' => sub {
    my $include = File::Temp->new(UNLINK => 1);
    print $include <<EOM;
+{
    included_directive => { message => "Yes, I'm included!" }
}
EOM
    $include->flush;

    my $file = File::Temp->new(UNLINK => 1);
    print $file <<EOM;
+{
    include("$include"),
    foo => {
        bar => 1,
        baz => [ 1..5]
    },
} 
EOM
    $file->flush;

    my $ctxt = Cirque::Context->bootstrap( config => $file );

    my $config = $ctxt->config;
    ok $config->{foo}, "foo exists";
    ok $config->{included_directive}, "included directive exists";
};
done_testing;