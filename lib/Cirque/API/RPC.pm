package Cirque::API::RPC;
use Cirque::Pragmas;
use Mouse;

with qw( Cirque::Trait::WithContainer );

sub call {
    my ($self, $method, $args) = @_;

    my $response = $self->get('RPC::Client')->jsonrpc( $method, $args );
    if ($response->{error}) {
        die "JSONRPC Error: $response->{error}->{message}";
    }
    return $response;
}

my $meta = __PACKAGE__->meta;

foreach my $subtype ( qw(projects add_query update_query del_query saved_queries) ) {
    my $response_key = 
        $subtype eq 'saved_queries' ? 'queries' :
        $subtype eq 'add_query'    ? 'query' :
        $subtype;
    $meta->add_method( "user_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "user.$subtype" => $args );
        return $response->{result}->{$response_key};
    });
}

foreach my $subtype ( qw( get_notify_checked notify_checked ) ) {
    $meta->add_method( "user_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "user.$subtype" => $args );
        return $response->{result};
    } );
}

foreach my $subtype ( qw(actions attachments comments) ) {
    $meta->add_method("issue_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "issue.$subtype" => $args );
        return $response->{result}->{$subtype};
    })
}

foreach my $subtype ( qw(milestones repositories projects) ) {
    $meta->add_method("project_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "project.$subtype" => $args );
        return $response->{result}->{$subtype};
    })
}

foreach my $subtype ( qw(branches sync) ) {
    $meta->add_method("repository_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "repository.$subtype" => $args );
        return $response->{result}->{$subtype};
    })
}

foreach my $subtype ( qw( set_subissues ) ) {
    $meta->add_method("issue_$subtype" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "issue.$subtype" => $args );
        return $response->{result};
    });
}

foreach my $action ( qw( add delete ) ) {
    $meta->add_method("project_member_$action" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "project.member.$action" => $args );
        return $response->{result};
    });
}

foreach my $action ( qw( history ) ) {
    $meta->add_method("issue_summarybyproject_$action" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "issue.summarybyproject.$action" => $args );
        return $response->{result};
    });
}

# These are all the same, so auto-generate them (refactor later if you need them later)
foreach my $comp ( qw(project issue issue_comment issue_attachment milestone repository issue_summarybyproject issue_relation issue_action user saved_query) ) {
    (my $rpc_method = $comp) =~ s/_/\./g;

    $meta->add_method("${comp}_create" => sub {
        my ($self, $args) = @_;
        my $response;
        $response = $self->call( "$rpc_method.create" => $args );
        $response = $self->call( "$rpc_method.fetch" => { id => $response->{result}->{id} } );
        return $response->{result};
    });
    $meta->add_method("${comp}_update" => sub {
        my ($self, $args) = @_;
        my $response;
        $response = $self->call( "$rpc_method.update" => $args );
        $response = $self->call( "$rpc_method.fetch" => { id => $response->{result}->{id} } );
        return $response->{result};
    });
    $meta->add_method("${comp}_fetch" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "$rpc_method.fetch" => $args );
        return $response->{result};
    });
    $meta->add_method("${comp}_search" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "$rpc_method.search" => $args );
        return $response->{result};
    });
    $meta->add_method("${comp}_delete" => sub {
        my ($self, $args) = @_;
        my $response = $self->call( "$rpc_method.delete" => $args );
        return $response->{result};
    });
}

$meta->add_method( "issue_preview" => sub {
    my ($self, $args) = @_;
    my $response = $self->call( "issue.preview" => $args );
    return $response->{result};
} );

$meta->add_method( "issue_comment_preview" => sub {
    my ($self, $args) = @_;
    my $response = $self->call( "issue_comment.preview" => $args );
    return $response->{result};
} );

no Mouse;

1;
