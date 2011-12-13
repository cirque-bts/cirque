package Cirque::Web::Controller::WithMemberInfo;
use Mouse::Role;

around 'execute' => sub {
    my ($next, $self, $action, $c) = @_;
    if ( $c->stash->{ member } = $self->login_member( $c ) ) {
        $c->stash->{ my_projects } = $self->load_my_projects( $c );
        $c->stash->{ notify_checked } = $self->get_notify_checked( $c );
    }
    $self->$next( $action, $c );
};

sub load_my_projects {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    my $member = $stash->{member};

    if ( $member ) {
        my $api = $c->get( 'API::RPC' );
        return $api->user_projects({ account_id => $member->{email} });
    }
    return ();
}

sub get_notify_checked {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    my $member = $stash->{member};

    if ( $member ) {
        my $api = $c->get( 'API::RPC' );
        my $row = $api->user_get_notify_checked({ account_id => $member->{email} });
        return $row->{notify_checked};
    }
    return ();
}


no Mouse::Role;
1;
