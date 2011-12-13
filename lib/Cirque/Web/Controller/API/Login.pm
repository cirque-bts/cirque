package Cirque::Web::Controller::API::Login;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller::API';

sub login {
    my ($self, $c) = @_;

    my $request = $c->request;
    if ($request->method eq 'POST') {
        my $member = $c->get('API::Authentication')->authenticate( {
            email => $request->param('email') || '',
            password => $request->param('password') || '',
        } );

        if ($member) {
            $request->session->{ member } = $member;
            return
                $c->render_json({
                    status => 1,
                    member => $member
                });
        }
    }
    
    if (my $member = $self->login_member($c)) {
        $c->render_json({ status => 1, member => $member });
    } else {
        $c->render_json({ status => 0 });
    }
}

no Mouse;

1;
