use Test::More;
use strict;
use t::Util qw(create_ctxt);


subtest "get_api_from_context" => sub {
    my $context = create_ctxt();
    isa_ok $context, 'Cirque::Context';
    can_ok $context, qw/ get /;

    my @objs = (
        { key => 'RPC::Client', expected => 'Cirque::Client' }, 
        { key => 'UUID', expected => 'Data::UUID' }, 
        { key => 'Cache', expected => 'Cache::Memcached::Fast' },
        { key => 'Localizer', expected => 'Data::Localize' },
        { key => 'Validator', expected => 'Cirque::DFV' },
        { key => 'API::Issue' }, 
        { key => 'API::IssueAction' },
        { key => 'API::IssueAttachment' },
        { key => 'API::IssueComment' },
        { key => 'API::IssueRelation' },
        { key => 'API::IssueSummaryByProject' },
        { key => 'API::Milestone' },
        { key => 'API::Project' },
        { key => 'API::RPC' },
        { key => 'API::Repository' },
        { key => 'API::Servicer' },
        { key => 'API::Email' },
        { key => 'Email::Template', expected => 'Text::Xslate' },
        { key => 'Web::Router', expected => 'Router::Simple' },
        { key => 'JSON', expected => 'JSON::XS' },
        { key => 'JSONRPC::Router', expected => 'Router::Simple' },
        { key => 'JSONRPC::Handler::Router', expected => 'Router::Simple' },
        { key => 'JSONRPC::Handler::Dispatcher', expected => 'JSON::RPC::Dispatch' },
    );
    for my $o ( @objs ) {
        note "get $o->{key}";
        $o->{expected} ||= "Cirque::".$o->{key};
        isa_ok $context->get( $o->{key} ), $o->{expected};
    }
};

done_testing;
