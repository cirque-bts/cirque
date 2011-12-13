package Cirque::Web::Controller::Issue::Comment;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller';

sub edit {
    my ( $self, $c ) = @_;
    my $match = $c->match;
    my $params = $c->request->parameters;
    my $author = $c->stash->{member} ? $c->stash->{member}->{author} : undef;
    my $api = $c->get('API::RPC');
    my $comment = $api->issue_comment_fetch( { id => $match->{comment_id} } );
    if ( defined $comment ) {
        $api->issue_comment_update( { id => $match->{comment_id}, body => $params->{body}, author => $author } );
    }
    $c->redirect( "/issue/".$match->{issue_id} );
};

1;

__END__

