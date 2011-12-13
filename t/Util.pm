package t::Util;
use strict;
use parent qw(Exporter);
use Cirque::Util qw( random_ascii_string );
use Carp ();
use DBI;
use Digest::MD5 ();
use Email::Send::Test;
use File::Basename ();
use File::Path ();
use Plack::Runner;
use Test::More;
use Test::mysqld;
use Test::TCP;
use Test::WWW::Mechanize;

our @EXPORT_OK = qw(
    api_credential
    invalid_api_credential
    assert_email_count
    browse
    browser_clear
    create_anon_project
    create_anon_repo
    create_ctxt
    gen_dummy_account
    get_repo
    get_bare_repo
    jsonrpc_fail
    jsonrpc_success
    login_as_dummy_account
    login_credentials
    start_each_servers
    start_plackup
);

our $BROWSER ;

sub start_plackup {
    my ($app, @args) = @_;
    note join ( ' ', '[plackup] Trying to boot', $app, @args );
    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            my @filtered_args;
            my %flags;
            while (my $opt = shift @args) {
                if ( $opt =~ /^(?:-p|--port)$/ ) {
                    shift @args;
                    next;
                }

                if ( $opt =~ /^--access-log$/ ) {
                    $flags{has_accesslog} = 1;
                } elsif ( $opt =~ /^(?:-s|--server)$/ ) {
                    $flags{has_server} = 1;
                }
                push @filtered_args, $opt;
            }

            if (! $flags{has_server} )  {
                push @filtered_args, '-s' => 'Standalone';
            }
            if (! $flags{has_accesslog}) {
                my $i = 0;
                my $test_name;
                while ( my @caller = caller($i++) ) {
                    if ($caller[1] =~ /\.t$/) {
                        $test_name = $caller[1];
                        last;
                    }
                }

                die "Could not find test name" unless $test_name;
                push @filtered_args, "--access-log", "$test_name.log";
            }

            my $runner = Plack::Runner->new();
            $runner->parse_options('--port' => $port, @filtered_args );
            $runner->run( $app );
        }
    );
    if ( $server ) {
        note join ( ' ', '[plackup] SUCESS booting', $app, @args );
    }
    else {
        diag join ( ' ', '[plackup] FAILURE to boot', $app, @args );
    }
    return $server;
}

sub dbh {
    Carp::confess( "No dsn given" ) unless $_[0];
    return DBI->connect(
        $_[0], 
        undef, 
        undef, 
        {
            RaiseError => 1, 
            AutoCommit => 1, 
            mysql_enable_utf8 => 1
        }
    );
}

sub assert_email_count ($) {
    my $n = shift;
    my @caller = caller();
    Email::Send::Test->clear;
    Cirque::Util::guard(sub {
        my @emails = Email::Send::Test->emails;
        is scalar( @emails ), $n,
            sprintf
                "Expected %d mails, got %d (guard created at %s line %d)",
                $n,
                scalar @emails,
                $caller[1],
                $caller[2]
        ;
        for my $email ( @emails ) {
            isa_ok $email, 'Email::Simple';
        }
    });
}

sub create_ctxt (;$$) {
    my ($config_file, $container_file) = @_;
    require Cirque::Context;

    $config_file ||= File::Spec->catfile( 't', 'config.pl' );
    $container_file ||= File::Spec->catfile( 'etc', 'container.pl' );
    Cirque::Context->bootstrap( config => $config_file, container => $container_file );
}

sub get_repo {
    my $repo = (split /=/, `git config --list | grep remote.origin.url`)[1];
    chomp $repo;
    return $repo;
}

sub create_anon_repo {
    return sprintf "http://%s.example.com/%s.git", random_ascii_string 8, random_ascii_string 12;
}

sub create_anon_project {
    my ($ctxt, $args) = @_;
    $ctxt->get('API::Project')->create( {
        name => random_ascii_string 12,
        slug => random_ascii_string 10,
        %{ $args || {} },
    });
}


sub jsonrpc_success ($) {
    my $json = shift;
    if ( ! ok ! $json->{error}, "jsonrpc was successful (no error)" ) {
        diag explain $json;
        return;
    }
    return 1;
}

sub jsonrpc_fail ($) {
    my $json = shift;
    if ( ! ok $json->{error}, "expecting jsonrpc to fail" ) {
        diag explain $json;
        return;
    }
    return 1;
}

sub api_credential {
    return ( api_key => $ENV{CIRQUE_WEB_API_KEY}, api_secret => $ENV{CIRQUE_WEB_API_SECRET} ); 
}

sub invalid_api_credential {
    return ( api_key => "toobad", api_secret => "deadbeef" ); 
}

sub get_bare_repo {
    my $url = shift;

    my $bare_dir = File::Spec->catfile( qw( t bare_repo ) );
    File::Path::make_path( $bare_dir ) unless -e $bare_dir;
    my $clone_dir = File::Spec->catfile( $bare_dir, Digest::MD5::md5_hex( $url ) );

    unless ( -e $clone_dir ) {
        system "git clone --bare -- $url $clone_dir";
    }

    return sub {
        my @command = @_;
        my $command_str = join " ", @command;
        if ( $command_str =~ /^delete$/i ) {
            File::Path::rmtree( $clone_dir );
        }
        else {
            my $curdir = File::Spec->curdir;
            Guard::guard {
                chdir $curdir;
            };
            chdir $clone_dir;
            return map { chomp $_; $_ } `git $command_str`;
        }
    };
}


sub browse (;@) {
    my ( $method, @params ) = @_;
    $BROWSER ||= Test::WWW::Mechanize->new;
    my @rtn;
    if ( $method ) {
        if ( $method =~ /^(get|head|post|put)(_ok)?$/ ) {
            $params[0] ||= '/';
            $params[0] = sprintf 'http://127.0.0.1:%d%s', $ENV{TEST_WEB_PORT}, $params[0];
        }
        unless ( @rtn = $BROWSER->$method( @params ) ) {
            my ( $warn ) = $BROWSER->content =~ /<textarea readonly>(.*)/m;
            diag explain join( ': ', "[ERROR]$method", $warn );
        }
    }
    return wantarray ? ( @rtn ) : $BROWSER;
}

sub browser_clear {
    $BROWSER = undef;
}

sub start_each_servers {
    my $jsonrpc = start_plackup "t/jsonrpc.psgi";
    $ENV{TEST_RPC_PORT} = $jsonrpc->port;

    my $webapp = start_plackup "t/webapp.psgi";
    $ENV{TEST_WEB_PORT} = $webapp->port;

    return {
        jsonrpc => $jsonrpc,
        webapp => $webapp,
    };
}

sub gen_dummy_account {
    my $account = lc( sprintf 'test%s@test%saddr.test', random_ascii_string 6, random_ascii_string 12 );
    $account =~ s/_/-/g;
    my $password = random_ascii_string 12;
    return ( $account, $password );
}

sub login_as_dummy_account {
    my ( $account, $password ) = login_credentials();
    browser_clear();
    browse get => '/login';
    browse submit_form => (
        fields => {
            email => $account,
            password => $password,
        },
    );
    return ( $account, $password );
}
    
sub login_credentials {
    return ( 'test@bts.example.com', 'passWord' );
}

1;
