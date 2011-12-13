use strict;
use File::Spec;
use Cache::Memcached::Fast;
use Cirque::Client;
use Cirque::API::Email;
use Cirque::DB;
use Cirque::DFV;
use Data::Localize;
use Data::UUID;
use JSON;
use Text::Xslate;

sub register_get {
    my ( $c, $key ) = @_;

    register "$key" => sub {
        my $c = shift;
        my $config = $c->get('config')->{"$key"} || {};
        my @args = ( %$config, container => $c );
        my $klass = "Cirque::$key";
        unless ( Mouse::Util::is_class_loaded( $klass ) ) {
            Mouse::Util::load_class( $klass );
        }
        if ( $klass->can('cache') ) {
            push @args, ( cache => $c->get('Cache') );
        }
        if ( $klass->DOES('Cirque::Trait::WithContainer') ) {
            push @args, ( container => $c );
        }
        $klass->new( @args );
    };

    $c->get( "$key" );
}

register 'RPC::Client' => sub {
    my $c = shift;
    my $config = $c->get('config')->{'RPC::Client'} || {};
    Cirque::Client->new(
        api_key    => $config->{api_key},
        api_secret => $config->{api_secret},
        url        => $config->{url} || "http://127.0.0.1:8080/rpc", # dummy default
    );
};

register 'UUID' => Data::UUID->new;

register 'Cache' => sub {
    my $c = shift;
    my $config = $c->get('config');
    my $cache_config = $config->{Cache} || {};
    $cache_config->{servers} ||= [ '127.0.0.1:12345' ];
    $cache_config->{namespace} ||= 'cirque.';
    $cache_config->{compress_threshold} ||= 10_000;
    if (! exists $cache_config->{utf8} ) {
        $cache_config->{utf8} = 1;
    }
    Cache::Memcached::Fast->new($cache_config);
};

register 'Localizer' => sub {
    my $c = shift;
    my $config = $c->get('config')->{'Localizer'};

    my $loc = Data::Localize->new();
    foreach my $lconfig (@{$config->{localizers}}) {
        $loc->add_localizer(%$lconfig);
    }
    $loc->set_languages('en', 'ja');
    $loc->auto( exists $config->{auto} ? $config->{auto} : 1 );

    return $loc;
};

register 'Validator' => sub {
    my $c = shift;
    my $profiles = $c->get('config')->{'Validator'}->{'profiles'} || File::Spec->catfile("etc", "profiles.pl");
    return Cirque::DFV->new( $profiles, container => $c );
};

foreach my $key ( qw(DB::Master DB::Slave01) ) {
    register $key => sub {
        my $c = shift;
        my $config = $c->get('config');
        my $db = Cirque::DB->new(
            # $config->{$key}  (for now)
            $config->{'DB::Master'},
        );
        return $db;
    }, { scoped => 1 };
}

register 'DB::Slaves' => sub {
    my $c = shift;
    return [ $c->get('DB::Slave01') ];
}, { scoped => 1 };
    
my @classes = qw(
    API::Hook
    API::Issue
    API::IssueAction
    API::IssueAttachment
    API::IssueComment
    API::IssueKeyword
    API::IssueRelation
    API::IssueSummaryByProject
    API::Milestone
    API::Project
    API::RPC
    API::Repository 
    API::Servicer
    API::SavedQuery
    API::User
    API::UserNotifyChecked
);
foreach my $name ( @classes ) {
    my $key = $name;
    my $klass = "Cirque::$key";
    Mouse::Util::load_class($klass);
    register $key => sub {
        my $c = shift;
        my $config = $c->get('config')->{$key} || {};
        my @args = ( %$config, container => $c );
        if ( $klass->can('cache') ) {
            push @args, ( cache => $c->get('Cache') );
        }
        $klass->new( @args );
    };
}

register 'API::Authentication' => sub {
    my $c = shift;
    my $config = $c->get('config')->{'API::Authentication'};
    my $type = $config->{type} || 'Simple';
    my $key = "API::Authentication::$type";
    return register_get($c, $key);
};

register 'Web::Router' => sub {
    my $c = shift;
    my $routes = $c->get('config')->{'Web::Router'}->{routes} || File::Spec->catfile( 'etc', 'routes.pl' );
    return require $routes;
};

register 'API::Email' => sub {
    my $c = shift;
    my $config = $c->get('config')->{'API::Email'};
    my $sender = Cirque::API::Email->new( %{ $config } );
    return $sender;
};

register 'Email::Template' => sub {
    my $c = shift;
    my $config = $c->get('config')->{'Email::Template'};
    my $loc = $c->get('Localizer');
    my $view = Text::Xslate->new( 
        %{ $config },
        function => {
            loc => sub { $loc->localize( @_ ) },
        },
    );
    return $view;
};

register 'JSON' => sub {
    JSON->new->utf8;
};

register 'JSONRPC::Router' => sub {
    my $c = shift;
    my $routes = $c->get('config')->{'JSONRPC::Router'}->{routes} || File::Spec->catfile( 'etc', 'jsonrpc', 'routes.pl' );
    return require $routes;
};

register 'JSONRPC::Handler::Router' => sub {
    my $c = shift;
    my $routes = $c->get('config')->{'JSONRPC::Handler::Router'}->{routes} || File::Spec->catfile( 'etc', 'jsonrpc', 'handler_routes.pl' );
    return require $routes;
};

register 'JSONRPC::Handler::Dispatcher' => sub {
    my $c = shift;

    # XXX This is only used in Cirque::JSONRPC, so it's kind of a waste of
    # memory -- actually, most of the API:: will also suffer the same
    # problem. So in the future, we should have separate containers for
    # CUI, Web, and JSONRPC
    require JSON::RPC::Dispatch;
    JSON::RPC::Dispatch->new(
        coder => $c->get('JSON'),
        prefix => 'Cirque::JSONRPC::Handler',
        router => $c->get('JSONRPC::Handler::Router'),
    );
};
