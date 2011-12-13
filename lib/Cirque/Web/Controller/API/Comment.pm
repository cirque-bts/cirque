package Cirque::Web::Controller::API::Comment;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller::API';

sub register {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member; # FIXME 403

    my $project_id = $c->request->param('project_id');
    my $issue_id = $c->request->param('issue_id');
    my $body = $c->request->param('body');
    return unless length $body;

    my $comment = $c->get('API::RPC')->issue_comment_create({
        issue_id => $issue_id,
        project_id => $project_id,
        author => $member->{author},
        body  => $body
    });

    $c->render_json({ status => 1, comment => $comment });
}

no Mouse;

1;
