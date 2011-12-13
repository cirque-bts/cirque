use strict;
use File::Spec;

{
    JSONRPC => {
        authenticate => 1,
    },
    'RPC::Client' => {
        api_key => $ENV{CIRQUE_WEB_API_KEY},
        api_secret => $ENV{CIRQUE_WEB_API_SECRET},
        url => sprintf 'http://127.0.0.1:%d/rpc', do { $ENV{TEST_RPC_PORT} || 8080 },
    },
    'API::Worker' => {
        address => $ENV{WORKER_ADDRESS} || 'tcp://127.0.0.1:8888',
    },
    'Cache' => {
        servers => [ split /,/, $ENV{ TEST_MEMCACHED_SERVERS } ],
    },
    'API::Authentication' => {
        type => $ENV{TEST_AUTH_TYPE} || 'Null',
    },
    'API::Authentication::Simple' => {
        members => {
            'test@bts.example.com' => 'passWord',
        },
    },
    'DB::Master' => {
        connect_info  => [ 
            $ENV{ TEST_DSN },
            undef,
            undef,
            {
                RaiseError => 1,
                AutoCommit => 1,
                mysql_enable_utf8 => 1,
            },
        ],
        on_connect_do => q|SET sql_mode = 'STRICT_TRANS_TABLES'|,
    },

    'Web::View::Xslate' => {
        path => [
            path_to('view'),
            path_to('view', 'include'),
        ],
        syntax => 'TTerse',
        module => [ 'Cirque::Xslate::Bridge', 'Text::Xslate::Bridge::TT2Like' ],
    },
    'API::Hook' => {
        endpoints => {
            # Leave blank or all hell breaks loose
        },
        endpoint_map => [
            # Leave blank or all hell breaks loose
            # qr/^issue\./ => [ 'email' ],
        ],
    },
};

