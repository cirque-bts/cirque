package Cirque::API::UserNotifyChecked;
use Mouse;

with qw(
    Cirque::API::WithTeng
);

around update => sub {
    my ( $next, $self, $args ) = @_;
    if ( $args->{account_id} ) {
        my ( $row ) = $self->search( { account_id => $args->{account_id} } );
        if ( $row ) {
            $args->{id} = $row->id;
        }
    }
    $self->$next( $args );
};

no Mouse;

1;
