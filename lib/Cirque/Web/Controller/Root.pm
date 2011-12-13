package Cirque::Web::Controller::Root;
use Cirque::Pragmas;
use Mouse;
use JSON ();

extends 'Cirque::Web::Controller';

around BUILDARGS => sub {
    my ($next, $self, @args) = @_;
    my $args = $self->$next(@args);
    $args->{namespace} ||= '';
    $args;
};

sub index {
    my ($self, $c) = @_;
    $c->redirect( "/mypage" );
}

sub mypage {
    my ($self, $c) = @_;

    if ( ! $c->stash->{member} ) {
        return $self->assert_login($c);
    }

    my $stash = $c->stash;
    my $api = $c->get('API::RPC');
    $stash->{saved_queries} = $api->user_saved_queries({
        account_id => $c->stash->{member}->{email}
    });
    if ( ref $stash->{saved_queries} eq 'ARRAY' ) {
        for my $query ( @{$stash->{saved_queries}} ) {
            $query->{query} = JSON::decode_json( $query->{query} );
        }
    }
}

sub notifications {
    my ($self, $c)= @_;
}

sub error {
    my ($self, $c) = @_;
}

no Mouse;

1;
