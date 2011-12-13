use strict;
use Test::More;
use File::Spec;
use t::Util qw(create_ctxt api_credential);
use Cirque::Util qw(random_ascii_string);
use Cirque::API::Servicer;

my $context = create_ctxt();

my $api = Cirque::API::Servicer->new(
    container => $context->container
);

isa_ok $api, 'Cirque::API::Servicer';

eval {
    $api->delete( { id => "test" } );
};
diag $@;

my $data = {
    api_key => random_ascii_string 12,
    api_key => random_ascii_string 20,
    id => "test",
    name => "test",
} ;

my $servicer = $api->create( $data );

for my $key ( keys %$data ) {
    is $servicer->$key, $data->{ $key };
}

done_testing;
