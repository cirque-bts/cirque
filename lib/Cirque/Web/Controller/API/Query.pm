package Cirque::Web::Controller::API::Query;
use Cirque::Pragmas;
use Mouse;
use JSON ();

extends qw/ Cirque::Web::Controller::API /;

sub save {
    my ( $self, $c ) = @_;

    my $params = $c->request->parameters->as_hashref_multi;
    my $member = $c->stash->{member};

    return unless $member;

    delete $params->{'_'};
    my $name = delete $params->{name};
    my $sequence = defined $params->{sequence} ? delete $params->{sequence} : undef;

    my $api = $c->get('API::RPC');
    if ( $params->{id} ) {
        $api->user_update_query( {
            id => $params->{id},
            query => JSON::encode_json($params),
            name => ref $name eq 'ARRAY' ? $name->[0] : $name,
        } );
    }
    else {
        $api->user_add_query( {
            account_id => $member->{email},
            query => JSON::encode_json($params),
            name => ref $name eq 'ARRAY' ? $name->[0] : $name,
        } );
    }

    if ( defined $sequence ) {
        $api->saved_query_update( {
            id => $params->{id}->[0],
            sequence => $sequence->[0],
        } );
    }

    $c->render_json({ status => 1 });
}

sub remove {
    my ( $self, $c ) = @_;

    my $params = $c->request->parameters->as_hashref;
    my $member = $c->stash->{member};

    return unless $member;

    my $api = $c->get('API::RPC');
    $api->user_del_query( {
        account_id => $member->{email},
        id => $params->{id},
    } );

    $c->render_json({ status => 1 });
}

sub fetch {
    my ( $self, $c ) = @_;

    my $params = $c->request->parameters->as_hashref;
    my $member = $c->stash->{member};

    return unless $member;

    my $api = $c->get('API::RPC');
    my $row = $api->saved_query_fetch({ id => $params->{id} });

    $c->render_json({ status => 1, query => $row });
}


1;

__END__
