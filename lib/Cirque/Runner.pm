package Cirque::Runner;
use Cirque::Pragmas;
use Config;
use Mouse;
use Plack::Runner;
use POSIX ();
use Server::Starter ();

sub run {
    my ($self, $c) = @_;

    my %services;
    local %SIG;

    my @signals = (
        [ INT  => 'TERM' ], 
        [ HUP  => 'HUP'  ],
        [ TERM => 'TERM' ],
    );
    foreach my $sigpair ( @signals ) {
        my ($sendsig,  $recvsig) = @$sigpair;
        $SIG{"$recvsig"} = sub {
            print STDERR "cirque runner: received $recvsig\n";
            while ( my ($service, $pid) = each %services) {
                print STDERR " + sending $sendsig to $service ($pid)\n";
                {
                    no strict 'refs';
                    kill &{"POSIX::SIG$sendsig"}(), $pid;
                }
            }
        };
    };

    my $chld; $chld = sub {
        my $pid;
        while (($pid = waitpid(-1, POSIX::WNOHANG())) > 0) {
            # noop
        }
        $SIG{CHLD} = $chld;
    };
    $SIG{CHLD} = $chld;

    $services{jsonrpc} = $self->spawn_rpc_server($c);
    $services{webapp}  = $self->spawn_web_server($c);

    wait;
}

sub spawn_psgi {
    my ($self, $name, $params ) = @_;

    my $pid = fork();
    if ( $pid ) {
        return $pid;
    }
    else {
        $0 = "cirque $name (superdaemon)";

        # XXX WTF? for some reason SIGCHLD gets propagated to the
        # process that start_server spawns, but EXPLICITLY deleting
        # it works.
        delete $SIG{CHLD};

        local %SIG;

        my $psgi = delete $params->{ psgi };
        my $listen = delete $params->{ listen };

        my @cmd = (
            $Config{ perlpath },
            '-MPlack::Runner',
            '-e',
            <<'EOM',
                my $runner = Plack::Runner->new;
                $runner->parse_options("-s" => "Starlet", @ARGV);
                $runner->run();
EOM
            '-a',
            $psgi
        );

        print "*** Starting $name service on $listen\n";
        local $ENV{PERL5LIB} = join $Config{ path_sep }, @INC;
        Server::Starter::start_server(
            port => [ $listen ],
            exec => \@cmd,
        );
        exit 0;
    }
}

sub spawn_rpc_server {
    my ($self, $c) = @_;

    my $config = $c->config;
    my $listen = $config->{ Runner }->{ JSONRPC }->{ listen } || '0:8080';

    $self->spawn_psgi( JSONRPC => { 
        psgi   => $c->path_to( qw/ etc jsonrpc app.psgi / ),
        listen => $listen,
    } );
}

sub spawn_web_server {
    my ($self, $c) = @_;

    my $config = $c->config;
    my $listen = $config->{ Runner }->{ Webapp }->{ listen } || '0:5000';
    my $rpc    = $config->{ Runner }->{ JSONRPC }->{ listen } || '0:8080';

    local $ENV{ CIRQUE_RPC_URL } = sprintf "http://%s/rpc", $rpc;
    $self->spawn_psgi( Web => { 
        psgi   => $c->path_to( "etc", "app.psgi" ),
        listen => $listen,
    } );
}

no Mouse;

1;
