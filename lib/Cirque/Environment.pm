package Cirque::Environment;
use strict;

sub load_dotcloud_env {
    my $file = shift;

    my $json = '';
    open my $fh, '<', $file or die "load_dotcloud_env: could not read file $file";
    $json .= join '', <$fh>;
    close $fh;

    require JSON;
    my $env = JSON::decode_json( $json );

    # $env comes first, because runtime parameters (%ENV) has
    # higher precedence
    %ENV = (%$env, %ENV);

    my $dbname = uc( $ENV{ CIRQUE_DOTCLOUD_DB_SERVICE_NAME } || 'db' );

    if ( my $url = $ENV{ DOTCLOUD_JSONRPC_HTTP_URL }) {
        # XXX This is activated when you're running in multi-service mode
        $ENV{ CIRQUE_JSONRPC_URL } = $url;
    } else {
        # XXX This is activated when you're running in single-service mode
        $ENV{ CIRQUE_JSONRPC_LISTEN_PORT } = $ENV{ PORT_JSONRPC };
        $ENV{ CIRQUE_JSONRPC_LISTEN_HOST } = '0.0.0.0';
        $ENV{ CIRQUE_WEB_LISTEN_PORT }     = $ENV{ PORT_WEB };
        $ENV{ CIRQUE_WEB_LISTEN_HOST }     = '0.0.0.0';
    }


    $ENV{ CIRQUE_MYSQL_DSN } ||= sprintf( 
        "dbi:mysql:dbname=cirque;host=%s;port=%d",
        $ENV{ "DOTCLOUD_${dbname}_MYSQL_HOST" },
        $ENV{ "DOTCLOUD_${dbname}_MYSQL_PORT" }
    );
    $ENV{ CIRQUE_MYSQL_USERNAME } ||= $ENV{ "DOTCLOUD_${dbname}_MYSQL_LOGIN" };
    $ENV{ CIRQUE_MYSQL_PASSWORD } ||= $ENV{ "DOTCLOUD_${dbname}_MYSQL_PASSWORD" };

}

BEGIN {
    my $dotcloud_envfile = $ENV{ DOTCLOUD_ENVIRONMENT_JSON } || '/home/dotcloud/environment.json';
    if (-f $dotcloud_envfile) {
        load_dotcloud_env($dotcloud_envfile);
    }
}

1;

