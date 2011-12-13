package Cirque::Trait::Controller::WithSubsession;
use Mouse::Role;

sub get_subsession_container {
    my ($self, $c) = @_;
    return $c->request->session->{ 'cirque.subsessions' } ||= {
        __created_on => time(),
    };
}

sub new_subsession_id {
    my ($self, $c) = @_;
    return $c->get('UUID')->create_from_name_str( 'Cirque', join '.',
        Time::HiRes::time(),
        {},
        rand(),
        $$
    );
}

sub new_subsession {
    my ($self, $c, $initial_value) = @_;
    my $container = $self->get_subsession_container($c);
    my $sid;
    do {
        $sid = $self->new_subsession_id($c);
    } while ( exists $container->{ $sid } );

    $container->{$sid} = $initial_value || {};
    return $sid;
}

sub get_subsession {
    my ($self, $c, $sid) = @_;
    $self->get_subsession_container($c)->{ $sid };
}

sub clear_subsession {
    my ($self, $c, $sid) = @_;
    my $container = $self->get_subsession_container($c);
    delete $container->{$sid};
}

no Mouse::Role;

1;
