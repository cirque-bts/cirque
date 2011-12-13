package Cirque::API::Hook;
use Cirque::Pragmas;
use Cirque::Context;
use Mouse;

with qw(Cirque::Trait::WithContainer);

has endpoint_map => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[] },
);

has endpoints => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

sub BUILD {
    my $self = shift;

    my $map = $self->endpoint_map;
    foreach my $i ( 0 .. scalar @$map / 2 ) {
        my $pattern = $map->[$i * 2];
        next unless $pattern;
        if ( ! ref $pattern ) { # not a qr// regexp
            $map->[$i * 2] = qr/\Q$pattern\E/;
        }
    }
    $self;
}

sub get_endpoints {
    my ($self, $action) = @_;

    my $map = $self->endpoint_map;
    my $action_name = $action->action;
    foreach my $i ( 0 .. scalar @$map / 2 ) {
        my $re = $map->[$i * 2];
        next unless $re;
        if ($action_name =~ /$re/) {
            my $handlers = $map->[$i * 2 + 1];
            return wantarray ? @$handlers : $handlers;
        }
    }
    return wantarray ? () : [];
}

sub process {
    my ($self, $job) = @_;

    # dispatch to a notification endpoint based on the action type
    my $action_id = $job->{action};
    my $action    = $self->get( 'API::IssueAction' )->find( $action_id );
    if (! $action) {
        Carp::cluck( "No action found for $action_id?" );
        return;
    }
    $self->call_endpoint_hooks( $action );
}

sub call_endpoint_hooks {
    my ($self, $action) = @_;
    foreach my $endpoint_name ( $self->get_endpoints( $action ) ) {
        eval {
            $self->call_hook( $action, $endpoint_name );
        };
        if ($@) {
            print STDERR "Notify: failed to call hooks for $endpoint_name: $@\n";
        }
    }
}

sub call_hook {
    my ( $self, $action, $endpoint_name ) = @_;

    my $endpoint = $self->endpoints->{ $endpoint_name };
    unless ( defined $endpoint ) {
        Carp::croak sprintf "[%s] Undefined endpoint '%s'", __PACKAGE__, $endpoint_name;
    }

    my $tmpfile = $self->make_tmpfile( $action );
    if ( ref $endpoint eq 'CODE' ) {
        local *STDIN = $tmpfile;
        $endpoint->();
    } else {
        system "$endpoint < $tmpfile";
    }
}

sub make_tmpfile {
    my ( $self, $action ) = @_;

    my $json = $self->build_json_data( $action );

    my $tmpfile = File::Temp->new(UNLINK => 1);
    $tmpfile->print( $json."\n" );
    $tmpfile->flush();
    $tmpfile->seek(0, 0);
    return $tmpfile;    
}

sub build_json_data {
    my ( $self, $action ) = @_;

    my $data = $action->get_columns;

    my $project = $self->get('API::Project')->find( delete $data->{project_id} );
    $data->{project} = $project ? $project->get_columns : {};

    if ( $project ) {
        my $members = [ 
            map { $_->get_columns }
            $self->get('API::Project')->load_members( $project->id ) 
        ];
        $data->{project}->{members} = $members;
    }

    my $issue = $self->get('API::Issue')->find( delete $data->{issue_id} );
    $data->{issue} = $issue ? $issue->get_columns : {};

    my %reference_map = (
        'comment' => 'IssueComment',
        'attach' => 'IssueAttachment',
    );

    for my $key ( keys %reference_map ) {
        my $apiname = $reference_map{"$key"};
        if ( $data->{action} eq "issue.$key" ) {
            my $comment = $self->get("API::$apiname")->find( delete $data->{reference} );
            $data->{"$key"} = $comment ? $comment->get_columns : {};
        }
    }
    if ( $data->{action} eq 'issue.attach' ) {
        delete $data->{attach}->{body};
    }

    return $self->get('JSON')->encode( $data );
}

no Mouse;

1;

__END__
