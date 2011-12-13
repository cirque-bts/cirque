use strict;
use Test::More;
use t::Util qw(create_ctxt);

my $ctxt = create_ctxt;

my $api = $ctxt->get('API::Email');
isa_ok $api, "Cirque::API::Email";

my @addr = $api->extract_valid_addresses( 'daisukem@bts.example.com', 'daisuke' );
ok @addr;
if (! is_deeply( \@addr, [ 'daisukem@bts.example.com' ] ) ) {
    diag explain @addr;
}
done_testing;
