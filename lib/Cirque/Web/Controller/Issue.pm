package Cirque::Web::Controller::Issue;
use Cirque::Pragmas;
use Mouse;
use MIME::Base64 ();
use POSIX ();
use JSON ();

extends 'Cirque::Web::Controller';

around qw(view edit comment) => \&_load_issue;
sub _load_issue {
    my ($next, $self, $c) = @_;

    my $match = $c->match;
    my $issue_id = $match->{issue};
    my $issue = $c->get('API::RPC')->issue_fetch( { id => $issue_id } );
    if (! $issue) {
        $self->NOT_FOUND($c);
        return;
    }

    my $stash = $c->stash;
    $stash->{issue_id} = $issue_id;
    $stash->{issue} = $issue;
    $self->$next($c);
};

sub index {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    my $params = $c->request->parameters;
    my $resolution = $params->{resolution} || { 'NOT IN' => [ 'fixed', 'closed' ] };
    if ($resolution eq 'all') {
        undef $resolution;
    }
    
    my $sortcol = $params->{sortcol} || 'severity';
    my $sortorder = $params->{sortorder} || 'ASC';

    my %where = ();
    if ($resolution) {
        $where{ resolution } = $resolution;
    }

    my $rpc_api = $c->get('API::RPC');
    my $issues = $rpc_api->issue_search({
        where => \%where,
        option => {
            order_by => join ' ', $sortcol, $sortorder,
        }
    });
    my $project = {};
    for my $issue ( @$issues ) {
        my $project_id = $issue->{project_id};
        $project->{$project_id} = $rpc_api->project_fetch( { id => $project_id } );
    }
    $stash->{issues} = $issues;
    $stash->{project} = $project;
}

sub report_start {
    my ($self, $c) = @_;

    my $member = $self->assert_login($c);
    return unless $member;

    my $match = $c->match;
    my $stash = $c->stash;

    my $rpc_api = $c->get('API::RPC');
    my $project = $rpc_api->project_fetch( { slug => $match->{slug} });
    $stash->{project} = $project;
    $stash->{milestones} = [ sort { $a->{id} <=> $b->{id} } @{$rpc_api->project_milestones( { project_id => $project->{id} } )} ];
    if (defined( my $id = $match->{parent_issue_id} )) {
        $stash->{parent_issue} = $rpc_api->issue_fetch( { id => $id } );
    }
}

sub report_confirm {
    my ($self, $c) = @_;

    my $match = $c->match;
    my $stash = $c->stash;
    my $rpc_api = $c->get('API::RPC');
    my $project = $rpc_api->project_fetch( { slug => $match->{slug} } );
    my $member = $self->assert_login( $c );
    return unless $member;

    $stash->{project} = $project;

    # show confirm
    my $request = $c->request;
    if ( $request->method eq 'POST' ) {
        my $issue;
        eval {
            $issue = $rpc_api->issue_create({
                %{ $c->request->parameters },
                author => $member->{author},
                project_id => $project->{id},
            });
        };
        if ( $@ ) {
            $stash->{error} = $@;
            local $@;
            if ( $stash->{error} =~ /^JSONRPC Error: Validation failed:\n   (.+?) = \[ missing \]/ ) {
                ( $stash->{invalid} ) = $stash->{error} =~ /^JSONRPC Error: Validation failed:\n   (.+?) = \[ missing \]/;
                delete $stash->{error};
            }
            else {
                Carp::croak "[REPORT_CONFIRM] $@";
            }
            # when caught error, go back to the form and represent error message.
            $c->stash->{fdat} = $request->parameters->as_hashref;
        }
        else {
            my $iter = 1;
            while ( my $file = $request->uploads->{"attach_$iter"} ) {
                _attach( $rpc_api,
                    issue_id   => $issue->{id},
                    author     => $member->{author},
                    file       => $file,
                );
                $iter++;
            }
            $c->redirect( "/issue/" . $issue->{id} );
        }
    }
}

sub view {
    my ($self, $c) = @_;
    my $stash = $c->stash;
    my $rpc_api = $c->get('API::RPC');

    my $issue = $stash->{issue};
    my $issue_id = $stash->{issue_id};
    $stash->{member} = $c->request->session->{'member'};
    $stash->{project} = $rpc_api->project_fetch( { id => $issue->{project_id} });
    $stash->{comments} = [ reverse @{ $rpc_api->issue_comments({ issue_id => $issue_id } ) } ];
    $stash->{actions} = [ reverse @{ $rpc_api->issue_actions({ issue_id => $issue_id } ) } ];
    $stash->{files} = [ reverse @{ $rpc_api->issue_attachments( { issue_id => $issue_id } ) } ];
    $stash->{milestones} = [ sort { $a->{id} <=> $b->{id} } @{$rpc_api->project_milestones( { project_id => $issue->{project_id} } )} ];
    $stash->{milestone} = $rpc_api->milestone_fetch( { id => $issue->{milestone_id} } ); 
}

sub comment {
    my ($self, $c) = @_;
    my $member = $self->assert_login( $c );

    my $match = $c->match;
    my $issue = $c->stash->{issue};
    my $comment = $c->get('API::RPC')->issue_comment_create({
        issue_id => $issue->{id},
        project_id => $issue->{project_id},
        author => $member->{author},
        body  => $c->request->param('body')
    });

    $c->redirect( "/issue/" . $issue->{id} );
}

sub edit {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $match = $c->match;
    my $stash = $c->stash;
    my $api = $c->get('API::RPC');
    my $issue = $stash->{issue};
    my $comment;

    my $input = $c->request->parameters->as_hashref;
    my @in_subissues;
    if ( $input->{subissue} ) {
        @in_subissues = $input->{subissue} =~ /(\d+)/g;
    }
    delete $input->{subissue};
    if ( $input->{comment} ) {
        $comment = delete $input->{comment};
    }

    $api->issue_update( {
        %$input,
        id => $issue->{id},
        author => $member->{author},
    } );

    $api->issue_set_subissues( { 
        author    => $member->{author}, 
        issue_id  => $issue->{id}, 
        subissues => [ @in_subissues ],
    } );

    if ( $comment ) {
        $api->issue_comment_create({
            issue_id => $issue->{id},
            project_id => $issue->{project_id},
            author => $member->{author},
            body  => $comment,
        });
    }

    $c->redirect( "/issue/" . $issue->{id} );
}

sub assigned {
    my ($self, $c) = @_;

    my $match = $c->match;
    my $stash = $c->stash;

    my $api = $c->get('API::RPC');
    my $issues = $api->issue_search( { where => { assigned_to => $match->{user_id} } } );

    $stash->{issues} = $issues;
    $stash->{assigned_to} = $match->{user_id};
}
    
sub attach {
    my ($self, $c) = @_;

    my $file = $c->request->uploads->{file};
    my $issue_id = $c->request->param('issue_id');
    my $member = $self->assert_login( $c );
    my $api = $c->get('API::RPC');
    my $issue = $api->issue_fetch( { id => $issue_id } ) or
        die "No issue XXX FIX THIS ERROR MESSAGE";

    _attach( $api,
        issue_id   => $issue_id,
        author     => $member->{author},
        file       => $file,
    );

    $c->redirect( "/issue/" . $issue_id );
}

sub list {
    my ($self, $c) = @_;
    $c->stash->{issues} = $c->get('API::RPC')->issue_search( {
        where => { 
            resolution => { 
                'NOT IN' => [qw/ closed fixed /] 
            } 
        },
        option => { 
            order_by => 'id',
        },
    } );
}

sub info {
    my ($self, $c) = @_;
    $c->stash->{issue} = $c->get('API::RPC')->issue_fetch( { id => $c->match->{issue} } );
    $c->stash->{project} = $c->get('API::RPC')->project_fetch( { id => $c->stash->{issue}->{project_id} } );
}

sub relation {
    my ($self, $c) = @_;

    my $api = $c->get('API::RPC');
    my $member = $self->assert_login( $c );

    $api->issue_relation_create( {
        issue_id        => $c->match->{issue_id}, 
        parent_issue_id => $c->match->{parent_issue_id},
        author      => $member->{author},
    } );

    $c->redirect( "/issue/". $c->match->{parent_issue_id} );
}

sub comment_preview {
    my ($self, $c) = @_;
    my $body = $c->request->param('body');
    my $member = $c->request->session->{'member'};
    $self->view( $c );
    $c->stash->{comments} = [ $c->get('API::RPC')->issue_comment_preview({ 
        id         => 0,
        project_id => $c->stash->{project}->{id},
        issue_id   => $c->stash->{issue}->{id},
        author     => $member->{author},
        body       => $body,
        created_on => POSIX::strftime( '%Y-%m-%d %H:%M:%S', localtime() ),
    }) ];
}

sub preview {
    my ($self, $c) = @_;

    my $match = $c->match;
    my $stash = $c->stash;

    $stash->{member} = $c->request->session->{'member'};

    my $rpc_api = $c->get('API::RPC');
    my $input = $c->request->parameters->as_hashref;
    my @time = localtime;

    my $project = $rpc_api->project_fetch( { slug => $match->{slug} } );
    $stash->{project} = $project;

    my $issue = $rpc_api->issue_preview({
        id => 0,
        project_id => $project->{id},
        resolution => $input->{resolution},
        author => $stash->{member}->{author},
        title => $input->{title},
        issue_type => $input->{issue_type},
        severity => $input->{severity},
        assigned_to => $input->{assigned_to},
        version => $input->{version},
        milestone_id => $input->{milestone_id},
        description => $input->{description},
        due_on => $input->{due_on},
        cc => $input->{cc},
        created_on => POSIX::strftime( '%Y-%m-%d %H:%M:%S', @time ),
        modified_on => POSIX::strftime( '%Y-%m-%d %H:%M:%S', @time ),
    });
    $stash->{issue} = $issue;

    $stash->{comments} = [];
    $stash->{actions} = [];
    $stash->{files} = [];
    $stash->{related} = {
        parent_issues => [],
        sub_issues    => [],
    };
    $stash->{milestones} = $rpc_api->project_milestones( { project_id => $issue->{project_id} } );
    $stash->{milestone} = $rpc_api->milestone_fetch( { id => $issue->{milestone_id} } ); 
}

sub _attach {
    my ( $api, %args ) = @_;

    my $body ;
    my $buf ;
    my $file = delete $args{file};

    open my $fh, '<', $file->path or die "Could not open uploaded file\n";
    binmode $fh;
    while ( $buf = <$fh> ) {
        $body .= $buf;
    }
    close $fh;
    $body = MIME::Base64::encode_base64( $body );

    $api->issue_attachment_create( { 
        %args, 
        filename   => $file->filename,
        mimetype   => $file->content_type,
        body       => $body 
    } );
}

no Mouse;

1;
