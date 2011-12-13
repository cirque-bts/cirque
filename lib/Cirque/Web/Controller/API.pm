package Cirque::Web::Controller::API;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller';

sub issue_fetch_with_rel {
    my ($self, $c, $issue_id) = @_;
    my $rpc_api = $c->get('API::RPC');
    my $issue = $rpc_api->issue_fetch( { id => $issue_id } );
    $issue->{project} = $rpc_api->project_fetch( { id => $issue->{project_id} });
    $issue->{project_name} = $issue->{project}->{name};
    $issue->{project_slug} = $issue->{project}->{slug};
    $issue->{comments} = $rpc_api->issue_comments( { issue_id => $issue_id } );
    $issue->{actions} = $rpc_api->issue_actions( { issue_id => $issue_id } );
    $issue->{files} = $rpc_api->issue_attachments( { issue_id => $issue_id } );
    $issue->{milestones} = $rpc_api->project_milestones( { project_id => $issue->{project_id} } );
    $issue->{milestone} = $rpc_api->milestone_fetch( { id => $issue->{milestone_id} } );
    $issue->{milestone} = $issue->{milestone}->{name};
    return $issue;
}

sub assert_login {
    my ($self, $c) = @_;
    my $member = $self->login_member($c);
    unless ($member) {
        my $res = $c->response;
        $res->status(403);
        $res->content_type('text/plain');
        $res->body('Forbidden');
        $c->finished(1);
    }
    return $member;
}

no Mouse;

1;
