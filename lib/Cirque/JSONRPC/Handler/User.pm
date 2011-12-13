package Cirque::JSONRPC::Handler::User;
use Mouse;
use Cirque::Pragmas;
use Time::Piece;

extends qw/ 
    Cirque::JSONRPC::Handler::CRUD
/;

sub projects {
    my ( $self, $params, $procedure, $c ) = @_;

    my $account_id = $params->{account_id};
    my %h;
    if (! $account_id) {
        $h{ projects } = [];
    } else {
        my @projects = $c->get('API::Project')->load_member_projects( $account_id );
        $h{ projects } = [ map { $_->get_columns } @projects ];
    }

    return \%h;
}

sub saved_queries {
    my ( $self, $params, $procedure, $c ) = @_;

    my $account_id = $params->{account_id};
    my %h;
    if (! $account_id) {
        $h{ queries } = [];
    } else {
        my @queries = $c->get('API::SavedQuery')->search(
            { account_id => $account_id },
            { order_by => 'sequence ASC' },
        );
        $h{ queries } = [ map { $_->get_columns } @queries ];
    }

    return \%h;
}

sub add_query {
    my ( $self, $params, $procedure, $c ) = @_;

    my $name       = $params->{name};
    my $account_id = $params->{account_id};
    my $query      = $params->{query};

    my $q = $c->get('API::SavedQuery')->create({
        name       => $name,
        account_id => $account_id,
        query      => $query
    });

    return { query => $q ? $q->get_columns : undef };
}

sub del_query {
    my ( $self, $params, $procedure, $c ) = @_;

    my $id         = $params->{id};
    my $account_id = $params->{account_id};

    $c->get('API::SavedQuery')->delete( {
        id => $id,
        account_id => $account_id,
    } );

    return {};
}

sub update_query {
    my ( $self, $params, $procedure, $c ) = @_;
    $c->get('API::SavedQuery')->update( $params );
    return {};
}

sub get_notify_checked {
    my ( $self, $params, $procedure, $c ) = @_;
    my ( $matched ) = $c->get('API::UserNotifyChecked')->search( $params );
    $matched = $matched ? $matched->get_columns : undef; 
    return $matched;
}

sub notify_checked {
    my ( $self, $params, $procedure, $c ) = @_;
    $c->get('API::UserNotifyChecked')->update( { 
        %$params, 
        notify_checked => localtime()->strftime('%Y-%m-%d %H:%M:%S'),
    } );
    return {};
}

no Mouse;

1;


