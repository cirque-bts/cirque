package Cirque::Web::Controller::Milestone;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller';
with 'Cirque::Trait::Controller::WithSubsession';

sub view {
    my ($self, $c) = @_;
    $self->load_project_by_slug($c);

    my $subsid = $c->stash->{sid} = $c->match->{sid};
    my $subsession = $self->get_subsession( $c, $subsid );
    if (! $subsession) {
        $c->redirect( "/notfound" );
        return;
    }
    $c->stash->{ subsid } = $subsid;
    my $stash = $c->stash;
    my $req = $c->request;

    if ( $req->method eq 'POST' ) {
        my $milestone_id = $c->match->{ milestone_id };
        my $slug = $c->match->{ slug };
        $c->get('API::RPC')->milestone_update( {
            %{ $req->parameters->as_hashref },
            id => $milestone_id,
        } );
        $c->redirect( "/admin/project/$slug" );
    }
    elsif (my $project = $stash->{project}) {
        my $match = $c->match;
        my $milestone = $c->get('API::RPC')->milestone_fetch({
            id => $match->{milestone_id}
        });
        $stash->{milestone} = $milestone;
    }
}

sub create_splash {
    my ($self, $c) = @_;
    $self->load_project_by_slug($c);
    my $sid = $self->new_subsession($c);
    my $slug = $c->stash->{ project }->{ slug };
    $c->redirect( "/admin/project/$slug/create/milestone/$sid" );
}

sub edit_splash {
    my ($self, $c) = @_;
    $self->load_project_by_slug($c);
    my $sid = $self->new_subsession($c);
    my $slug = $c->stash->{ project }->{ slug };
    my $milestone_id = $c->match->{ milestone_id };
    $c->redirect( "/admin/project/$slug/milestone/$milestone_id/$sid" );
}

sub create_milestone {
    my ($self, $c) = @_;
    my $subsid = $c->stash->{sid} = $c->match->{sid};
    my $subsession = $self->get_subsession( $c, $subsid );
    if (! $subsession) {
        $c->redirect( "/notfound" );
        return;
    }
    my $req = $c->request;
    $self->load_project_by_slug($c);
    my $slug = $c->stash->{ project }->{ slug };
    my $stash = $c->stash;
    $stash->{ subsid } = $subsid;
    if ( $req->method eq 'POST' ) {
        $c->get('API::RPC')->milestone_create( {
            %{ $req->parameters->as_hashref },
            project_id => $stash->{ project }->{ id },
        } );
        $c->redirect( "/admin/project/$slug" );
    }
}

no Mouse;

1;
