package Cirque::Web::Controller;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::WAF::Controller';
with qw/ Cirque::Web::Controller::WithMemberInfo /;

sub login_member {
    my ($self, $c) = @_;
    return $c->request->session->{'member'};
}

sub assert_login {
    my ($self, $c) = @_;
    my $member = $self->login_member( $c );
    if (! $member) {
        my $request = $c->request;
        my $uri = URI->new();
        $uri->path( "/login" );
        $uri->query_form(
            ".next" => $request->request_uri
        );
        $c->redirect( $uri );
    }
    return $member;
}

# XXX This shouldn't be here? Think about it later
sub load_project_by_slug {
    my ($self, $c) = @_;
    my $match   = $c->match;
    my $project = $c->get('API::RPC')->project_fetch( { slug => $match->{slug} } );
    if (! $project) {
        $self->NOT_FOUND($c);
        return ();
    }
    my $stash = $c->stash;
    $stash->{project} = $project;
    $stash->{slug} = $match->{slug};
    return $project;
}

no Mouse;

1;
