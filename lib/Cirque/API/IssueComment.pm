package Cirque::API::IssueComment;
use Cirque::Pragmas;
use Mouse;

with qw(
    Cirque::API::WithTeng
    Cirque::API::WithLinkExpand
    Cirque::API::WithHook
);

around create => sub {
    my ($next, $self, $args) = @_;
    if ( my $body = $args->{body}) {
        my $project = $self->get('API::Project')->find( $args->{project_id} );
        $args->{body} = $self->fixup_gitlink( $project, $body );
    }
    $self->$next($args);
};

around qw/ update / => sub {
    my ( $next, $self, $args ) = @_;

    my $author = $args->{author} ? delete $args->{author} : undef;
    my $pk = $args->{ $self->primary_key }
        or Carp::croak( "No primary key provided for update()" );
    my $handle = $self->get_handle('DB::Master');
    my $row    = $self->find( $pk )
        or Carp::croak( "No row by id $pk found" );

    if ( my $body = $args->{body}) {
        my $project = $self->get('API::Project')->find( $row->project_id );
        $args->{body} = $self->fixup_gitlink( $project, $body );
    }
    my $comment = $self->$next( $args );

    my $action = $self->add_action( $comment->issue_id => {
        action     => "issue.comment.edit",
        author     => $author,
        project_id => $comment->project_id,
        reference  => $comment->id,
        message    => "Comment was modified.",
    });

    $self->call_hook( $action );

    return $comment;
};

no Mouse;

1;

