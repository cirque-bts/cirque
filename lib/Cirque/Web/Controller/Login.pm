package Cirque::Web::Controller::Login;
use Cirque::Pragmas;
use Mouse;
use Plack::Session;
use Digest::MD5 ();

extends 'Cirque::Web::Controller';

sub login {
    my ($self, $c) = @_;

    my $request = $c->request;
    if ($request->method eq 'POST') {
        my $member = $c->get('API::Authentication')->authenticate( {
            email => $request->param('email'),
            password => $request->param('password'),
        } );

        if ($member) {
            $request->session->{ member } = $member;

            $c->redirect( $request->param('.next') || '/mypage' );
        }
    }
    $c->stash->{"next_uri"} = $request->param('.next');
}

sub logout {
    my ($self, $c) = @_;
    
    my $session = Plack::Session->new($c->request->env);
    if ($session) {
        $session->expire;
    }
    
    $c->redirect( '/' );
}

no Mouse;

1;
