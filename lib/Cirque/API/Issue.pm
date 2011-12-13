package Cirque::API::Issue;
use Cirque::Pragmas;
use Mouse;
use Scalar::Util ();
use MIME::Base64 ();

# XXX Think how to generalize later
our @CARP_NOT = qw(Mouse::Meta::Class);

with qw(
    Cirque::API::WithTeng
    Cirque::API::WithHook
    Cirque::API::WithLinkExpand
);

around 'create' => sub {
    my ($next, $self, $args) = @_;

    my $issue;
    my $parent_issue_id = delete $args->{parent_issue_id};
    my $handle = $self->get_handle( 'DB::Master' );
    my @milestones = sort { $a->id <=> $b->id } $self->get('API::Project')->load_milestones( $args->{project_id} );

    unless ( @milestones ) {
        Carp::croak( "Could not find associated milestones" );
    }

    $args->{milestone_id} ||= $milestones[0]->id if @milestones;

    if ( my $milestone = $self->get('API::Milestone')->find( $args->{milestone_id} ) ) {
        $args->{milestone_id} = $milestone->project_id eq $args->{project_id} ? 
                                $args->{milestone_id} :
                                $milestones[0]->id
        ;
    }
    else {
        $args->{milestone_id} = $milestones[0]->id;
    }

    if ( my $description = $args->{description}) {
        my $project = $self->get('API::Project')->find( $args->{project_id} );
        $args->{description} = $self->fixup_gitlink( $project, $description );
    }

    my $guard = $handle->txn_scope();
    eval {
        $issue = $self->$next($args);
        my $action = $self->add_action( $issue->id => {
            action     => "issue.create",
            author => $issue->author,
            project_id => $issue->project_id,
            reference  => $issue->id,
            message    => "added issue '".$issue->title."'",
        });

        # if there is a parent issue, create an associated relation
        if ( defined $parent_issue_id ) {
            # this issue is not yet committed :/
            # pass the object, not the id
            local $self->{FORCE_HANDLE} = 'DB::Master';
            $self->make_relation( {
                issue_id        => $issue->id,
                parent_issue_id => $parent_issue_id,
                author      => $issue->author,
            } );
        }
        $guard->commit;

        my $summary_api = $self->get('API::IssueSummaryByProject');
        $summary_api->delete_from_cache( { project_id => $issue->project_id } );

        $self->call_hook( $action );
    };
    if (my $e = $@) {
        eval { $guard->rollback };
        Carp::croak("Issue->create: $e");
    }

    return $issue;
};

around update => sub {
    my ($next, $self, $args) = @_;

    my $pk = $args->{ $self->primary_key }
        or Carp::croak( "No primary key provided for update()" );
    my $handle = $self->get_handle('DB::Master');
    my $row    = $self->find( $pk )
        or Carp::croak( "No row by id $pk found" );

    if ( my $description = $args->{description}) {
        my $project = $self->get('API::Project')->find( $row->project_id );
        $args->{description} = $self->fixup_gitlink( $project, $description );
    }

    $self->$next( $args );
};

around 'search' => sub {
    my ($next, $self, $where, $attrs) = @_;

    my $handle = $self->get_handle('DB::Slaves');
    my $me = $self->table;
    my $stmt = SQL::Maker::Select->new;
    $stmt->add_select("$me.*");
    $stmt->add_select("cirque_milestone.name" => "milestone");
    $stmt->add_select("cirque_project.name"   => "project_name");
    $stmt->add_select("cirque_project.slug"   => "project_slug");
    $stmt->add_join( $me => {
        table => "cirque_project",
        type => "inner",
        condition => "$me.project_id = cirque_project.id"
    } );
    $stmt->add_join( $me => {
        table => "cirque_milestone",
        type => "inner",
        condition => "$me.milestone_id = cirque_milestone.id"
    } );

    if ($where) {
        my $keyword = $where->{keyword} ? delete $where->{keyword} : undef;
        while ( my ($col, $val) = each %$where ) {
            $stmt->add_where( "$me.$col", $val );
        }
        if ( $keyword ) {
            my $kw_api = $self->get('API::IssueKeyword');
            my @id_list = map { $_->issue_id } $kw_api->search( {
                keyword => { LIKE => sprintf '%%%s%%', $keyword },
            } );
            $stmt->add_where( $me.".id", { IN => [ @id_list ] } );
        }
    }

    if ($attrs) {
        while ( my ($act, $val) = each %$attrs ) {
            my $method = "add_$act";
            my $code = $stmt->can($method);

            die("Cannot use \"$act\" as option \n") unless ref $code eq 'CODE';
            $code->( $stmt, $val );
        }
    }

    $handle->search_by_sql( $stmt->as_sql(), [ $stmt->bind ]);
};

sub find_action_by_commit_id {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Master');
    $handle->single(
        cirque_issue_action => {
            issue_id  => $args->{issue_id},
            commit_id => $args->{commit_id},
        }
    );
}

around 'update' => sub {
    my ($next, $self, $args) = @_;

    if ( $args->{parent_issue_id} ) {
        my $parent_issue_id = delete $args->{parent_issue_id};
        if ( my $parent_issue = $self->find( $parent_issue_id ) ) {
            $self->make_relation( {
                parent_issue_id => $parent_issue_id,
                issue_id        => $args->{id},
                author          => $args->{author},
            } );
        } 
    }

    my $author = $args->{author} ? delete $args->{author} : undef;
    my $changed = $self->check_changed( $args->{id}, $args );

    my $issue = $self->$next( $args );
    return $issue unless $changed;

    my $summary_api = $self->get('API::IssueSummaryByProject');
    $summary_api->delete_from_cache( { project_id => $issue->project_id } );

    my $action = $self->add_action( $issue->id => {
        action     => "issue.edit",
        author     => $author,
        project_id => $issue->project_id,
        message    => $changed->{message},
    });
    $self->call_hook( $action );

    return $issue;
};

sub add_comment {
    my ($self, $issue_id, $args) = @_;

    my $commit_id = delete $args->{commit_id};
    my $handle = $self->get_handle('DB::Master');
    my $guard = $handle->txn_scope();
    my $action;
    my $comment;
    eval {
        my $issue = $self->find( $issue_id );
        if (! $issue ) {
            die "No such issue $issue_id";
        }

        $comment = $self->get('API::IssueComment')->create( {
            issue_id   => $issue_id,
            project_id => $issue->project_id,
            author     => $args->{author},
            body       => $args->{body}
        });
        $action = $self->add_action( $issue_id => {
            action     => "issue.comment",
            author     => $args->{author},
            project_id => $issue->project_id,
            reference  => $comment->id,
            commit_id  => $commit_id,
            message    => "added a comment",
        } );
        $guard->commit;
    };
    if (my $e = $@) {
        eval { $guard->rollback };
        Carp::croak("Issue->add_action failed: $e");
    }

    $self->call_hook( $action );
    return $comment;
}

sub load_comments {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    my $iter = $handle->search(
        cirque_issue_comment => {
            issue_id => $args->{issue_id}
        }
    );
    $iter->all;
}

sub load_actions {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    my $iter = $handle->search(
        cirque_issue_action => {
            issue_id => $args->{issue_id}
        }
    );
    $iter->all;
}

sub add_file {
    my ($self, $issue_id, $args) = @_;

    my $handle = $self->get_handle('DB::Master');
    my $guard = $handle->txn_scope();
    my $action;
    my $attach;

    eval {
        my $issue = $self->find( $issue_id );
        if (! $issue ) {
            die "No such issue: $issue_id";
        }

        if ( ! $args->{body} && $args->{path} ) {
            open my $fh, '<', delete $args->{path} or
                die "Could not open file $args->{filename}";
            $args->{body} = $fh;
        }
        if ( Scalar::Util::openhandle($args->{body}) ) {
            my $fh = $args->{body};
            binmode $fh;
            my $body = do { local $/; <$fh> };
            $args->{body} = $body;
        }

        # XXX t/213_api_issue.t does not excercise this args->{encode}
        # so the behavior is not obvious
        if (delete $args->{encode}) {
            $args->{body} = MIME::Base64::decode_base64( $args->{body} );
        }
        $args->{filesize} ||= length( $args->{body} );

        $attach = $handle->insert( cirque_issue_attachment => {
            %$args,
            project_id => $issue->project_id,
            issue_id => $issue_id,
        });
        $action = $self->add_action( $issue_id, {
            action     => "issue.attach",
            author     => $args->{author},
            project_id => $issue->project_id,
            reference  => $attach->id,
            message    => "attached file '$args->{filename}'",
        } );
        $guard->commit;
    };    

    if (my $e = $@) {
        eval { $guard->rollback };
        Carp::croak( "Issue->add_file failed: $e" );
    }

    $self->call_hook( $action );

    return $attach || ();
}

sub load_files {
    my ($self, $args) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    return $handle->search(
        cirque_issue_attachment => {
            issue_id => $args->{issue_id}
        }
    );
}

sub remove_file {
    my ($self, $issue_id, $args) = @_;

    my $handle = $self->get_handle('DB::Master');
    my $guard = $handle->txn_scope();
    my $action;

    eval {
        my $issue = $self->find( $issue_id );
        if (! $issue ) {
            die "No such issue: $issue_id";
        }

        my $attach = $handle->single( cirque_issue_attachment => { 
            id => $args->{attach_id},
            issue_id => $issue_id,
        } );
        if ( ! $attach ) {
            die "Could not find attachment $args->{attach_id} for issue $issue_id";
        }
        $handle->delete( cirque_issue_attachment => { 
            id => $args->{attach_id},
            issue_id => $issue_id,
        } );

        $action = $self->add_action( $issue_id => {
            action     => "issue.remove_attach",
            author => $args->{author},
            project_id => $issue->project_id,
            reference  => $attach->filename,
            message    => sprintf "removed file '%s'", $attach->filename,
        } );
        $guard->commit;
    };    

    if (my $e = $@) {
        eval { $guard->rollback };
        Carp::croak( "Issue->remove_file failed: $e" );
    }

    $self->call_hook( $action );
}

sub load_parent_issues {
    my ($self, $id) = @_;
    $self->load_related( {issue_id => $id}, 'parent_issue_id' );
}

sub load_sub_issues {
    my ($self, $id) = @_;
    $self->load_related( {parent_issue_id => $id}, 'issue_id' );
}

sub load_related {
    my ($self, $args, $find_issue_by ) = @_;
    my $handle = $self->get_handle('DB::Master');
    my @parents;
    my $iter = $handle->search(
        cirque_issue_relation => $args
    );
    my $row;
    for my $relation ( $iter->all ) {
        $row = $handle->single( 'cirque_issue', {id => $relation->$find_issue_by} );
        push @parents, $row if defined $row;
    }
    return @parents;
}

sub make_relation {
    my ($self, $args) = @_;

    my $subissue = $self->find( $args->{issue_id} )
        or Carp::croak("Issue->make_relation: Could not find (sub) issue with id = $args->{issue_id}" );
    my $issue = $self->find( $args->{parent_issue_id} )
        or Carp::croak("Issue->make_relation: Could not find (parent) issue with id = $args->{parent_issue_id}" );
    my $rel_api = $self->get('API::IssueRelation');
    my $author = delete $args->{author};
    my $action;

    my ( $duplicated ) = $rel_api->search( $args );
    if ( ! $duplicated ) {
        $rel_api->create( $args );
        $action = $self->add_action( $issue->id, {
            action     => "issue.subissue_create",
            author => $author,
            project_id => $issue->project_id,
            reference  => $subissue->id,
            message    => "related issue '".$subissue->title."' as sub-issue",
        });
        $self->call_hook( $action );
    } 
}

sub remove_relation {
    my ( $self, $args ) = @_;

    my $subissue = $self->find( $args->{issue_id} );
    my $issue = $self->find( $args->{parent_issue_id} );
    my $rel_api = $self->get('API::IssueRelation');
    my $author = delete $args->{author};
    my $action;

    my $removed_rows = $rel_api->delete( $args );

    if ( $removed_rows ) {
        $action = $self->add_action( $issue->id, {
            action     => "issue.subissue_remove",
            author => $author,
            project_id => $issue->project_id,
            reference  => $subissue->id,
            message    => "relation for issue '".$subissue->title."' was removed",
        } );
        $self->call_hook( $action );
    }
}

sub set_subissues {
    my ( $self, $author, $issue_id, @subissues ) = @_;

    my $rel_api = $self->get('API::IssueRelation');
    my $issue = $self->find( $issue_id );

    if ( $issue ) {
        $rel_api->delete( { parent_issue_id => $issue->id } );
        for my $id ( @subissues ) { 
            $rel_api->create( { 
                parent_issue_id => $issue->id, 
                issue_id => $id,
            } );
        }
    }
}

sub check_changed {
    my ( $self, $id, $input ) = @_;

    my $milestone_api = $self->get('API::Milestone');
    my $issue = $self->find( $id );
    my %changes;
    my $message;

    while ( my ( $field, $value ) = each %$input ) {
        my $prev = $issue->$field || '';
        next unless defined $value;
        if ( $prev ne $value) {
            $changes{ $field } = [ $prev, $value ];
        }
    }
    return unless %changes;

    my @changes;
    while ( my ($field, $data) = each %changes ) {
        my ($before, $after) = @$data;
        if ( $field eq 'milestone_id' ) {
            $field = 'milestone';
            $before = $milestone_api->find( $before )->name;
            $after = $milestone_api->find( $after )->name;
        }
        if ( $field eq 'description' ) {
            if ( length $before > 16 ) {
                $before = substr($before, 0, 16) . '...';
            }
            if ( length $after > 16 ) {
                $after = substr($after, 0, 16) . '...';
            }
        }
        push @changes, "field $field from '$before' to '$after'";
    }
    $message = "Changed " . join ", ", @changes;

    return { columns => \%changes, message => $message };
}

no Mouse;

1;

__END__
