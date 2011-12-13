package Cirque::Web::Controller::API::Member;
use Cirque::Pragmas;
use Mouse;
use Digest::MD5 ();

extends 'Cirque::Web::Controller::API';

sub avatar {
    my ($self, $c) = @_;
    my $params = $c->request->parameters->as_hashref;
    my $api = $c->get('API::RPC');
    my $users = $api->user_search({ where => { account_id => $params->{account_id} } });
    my $url = $users ? $users->[0]->{icon} : '/static/images/nobody.png' ;
    $url ||= 'http://www.gravatar.com/avatar/'. Digest::MD5::md5_hex( $params->{account_id} ).'.png';
    
    $c->render_json({ status => 1, url => $url });
}

sub notify_checked {
    my ( $self, $c ) = @_;

    my $member = $c->stash->{member};
    return unless $member;

    my $params = $c->request->parameters->as_hashref;
    my $api = $c->get('API::RPC');
    $api->user_notify_checked({ account_id => $params->{account_id} });

    $c->render_json({ status => 1 });
}

sub get_notify_checked {
    my ( $self, $c ) = @_;

    my $member = $c->stash->{member};
    return unless $member;

    my $params = $c->request->parameters->as_hashref;
    my $api = $c->get('API::RPC');
    my $notify_checked = $api->user_get_notify_checked({ account_id => $params->{account_id} });
    $c->render_json({ status => 1, notify_checked => $notify_checked });
}

no Mouse;

1;
