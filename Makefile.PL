use strict;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME => "Cirque",
    VERSION_FROM => 'lib/Cirque.pm',
    PREREQ_PM => {
        'Cache::Memcached::Fast' => 0,
        'Class::Accessor::Lite' => 0,
        'DBI' => 0,
        'DBD::mysql' => 0,
        'Data::FormValidator' => 0,
        'Data::Localize' => 0,
        'Data::Recursive::Encode' => 0,
        'Data::UUID' => 0,
        'Digest::MD5' => 0,
        'Email::Address::Loose' => 0,
        'Email::Send' => 0,
        'Email::Simple' => 0,
        'Furl' => 0,
        'HTML::FillInForm' => 0,
        'HTML::Scrubber' => 0,
        'IO::Socket::SSL' => 0,
        'MIME::Base64' => 0,
        'Mouse' => '0.91',
        'MouseX::Foreign' => 0,
        'Plack' => 0,
        'Plack::Middleware::ReverseProxy' => 0,
        'Plack::Middleware::Session' => 0,
        'Plack::Session::Store::DBI' => 0,
        'Router::Simple' => 0,
        'Scope::Guard' => 0,
        'String::Urandom' => 0,
        'JSON' => 0,
        # recommends 'JSON::XS';
        'JSON::RPC' => 1.00,
        'Teng' => 0,
        'Text::MultiMarkdown' => 0,
        'Text::Xslate' => 1.5005,
        'Text::Xslate::Bridge::TT2Like' => 0,
        'Server::Starter' => 0,
        'Starlet' => 0,
        'String::Urandom' => 0,

        # for tests
        'Plack::App::Proxy' => 0,
        'Plack::Middleware::Static' => 0,
        'Plack::Middleware::Proxy::RewriteLocation' => 0,
        'Plack::App::URLMap' => 0,
        'Test::TCP' => 0,
        'Test::mysqld' => 0,
        'Test::WWW::Mechanize' => 1.38,
    },
    clean => {
        FILES => 't/*.log',
    }
);
