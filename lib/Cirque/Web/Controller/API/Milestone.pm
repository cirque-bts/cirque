package Cirque::Web::Controller::API::Milestone;
use Cirque::Pragmas;
use Mouse;
use Encode ();

extends 'Cirque::Web::Controller::API';

sub list {
    my ($self, $c) = @_;

    my $project_id = $c->request->param('project_id');
    my $milestones =
        $c->get('API::RPC')->project_milestones( { project_id => $project_id } );
    
    for my $milestone (@$milestones) {
        my $name = $milestone->{name};
        $milestone->{name} = Encode::decode_utf8($milestone->{name});
    }
    
    $c->render_json({ status => 1, milestones => $milestones });
}

sub fetch {
    my ($self, $c) = @_;

    my $milestone_id = $c->request->param('id');
    my $milestone = $c->get('API::RPC')->milestone_fetch( { id => $milestone_id } );
    if ( $milestone ) {
        $milestone->{name} = Encode::decode_utf8($milestone->{name});
    }

    $c->render_json({ status => 1, milestone => $milestone });
}

no Mouse;

1;
