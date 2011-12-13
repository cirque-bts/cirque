package Cirque::API::WithHook;

use Mouse::Role;

sub call_hook {
    my ( $self, $action ) = @_;
    $self->get('API::Hook')->process( { action => $action->id } );
}

sub add_action {
    my ($self, $issue_id, $args) = @_;
    my $handle = $self->get_handle('DB::Master');
    my $issue = $handle->single( 'cirque_issue', { id => $issue_id } );
    if (! $issue) { 
        Carp::croak "Could not find issue $issue_id";
    }

    $handle->insert( cirque_issue_action => {
        %$args,
        issue_id => $issue_id,
    } );
}

no Mouse::Role;

1;
__END__
