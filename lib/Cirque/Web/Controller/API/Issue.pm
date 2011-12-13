package Cirque::Web::Controller::API::Issue;
use Cirque::Pragmas;
use Mouse;
use MIME::Base64 ();
use Time::Piece;

extends 'Cirque::Web::Controller::API';

sub search {
    my ($self, $c) = @_;

    my $params = $c->request->parameters;
    my $sortcol = $params->{sortcol} || 'severity';
    my $sortorder = $params->{sortorder} || 'ASC';
    my $rpc_api = $c->get('API::RPC');

    my %where;

    # these keys are searched with LIKE 
    foreach my $key ( qw( title description ) ) {
        if (length $params->{$key}) {
            $where{$key} = { LIKE => sprintf '%%%s%%', $params->{$key} };
        }
    }

    # these keys can be specified multiple times
    foreach my $key ( qw(severity resolution) ) {
        if ( my @values = $params->get_all($key) ) {
            $where{$key} = { 'IN' => \@values };
        }
    }
    if (! $where{resolution} ) {
        $where{resolution} = { 'NOT IN' => [ 'fixed', 'closed' ] };
    } elsif ( grep { $_ eq 'all' } $params->get_all('resolution') ) {
        delete $where{resolution};
    }

    # these keys are searched for exact match
    foreach my $key ( qw( author target issue_type assigned_to version ) ) {
        if (length $params->{$key}) {
            $where{$key} = { LIKE => sprintf '%%%s%%', $params->{$key} };
        }
    }

    foreach my $key ( qw( keyword project_id ) ) {
        if (length $params->{$key}) {
            $where{$key} = $params->{$key};
        }
    }

    foreach my $key ( qw/project milestone/  ) {
        if (length $params->{$key}) {
            my $id_col = $key.'_id';
            my $method = $key.'_search';
            my $matched = $rpc_api->$method({ where => {
                name => { LIKE => sprintf '%%%s%%', $params->{$key} }
            } });
            $where{$id_col} = [];
            foreach my $rec ( @{$matched} ) {
                push @{$where{$id_col}}, $rec->{id};
            }
        }
    }

    if (length $params->{fresh}) {
        $where{modified_on} = { '>=' => localtime(time - (86400*3))->strftime('%Y-%m-%d %H:%M:%S') };
    }

    my $issues = $rpc_api->issue_search({
        where => \%where,
        options => {
            order_by => join ' ', $sortcol, $sortorder,
        }
    });

    $c->render_json({ status => 1, issues => $issues });
}

sub info {
    my ($self, $c) = @_;

    my $issue = $self->issue_fetch_with_rel($c, $c->request->param('id'));

    $c->render_json({ status => 1, issue => $issue });
}

sub register {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $rpc_api = $c->get('API::RPC');
    my $res = $rpc_api->issue_create({
        %{ $c->request->parameters },
        author => $member->{author}
    });

    my $issue = $self->issue_fetch_with_rel($c, $res->{id});

    $c->render_json({ status => 1, issue => $issue });
}

sub update {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $rpc_api = $c->get('API::RPC');
    my $res = $rpc_api->issue_update( {
        %{ $c->request->parameters },
        author => $member->{author}
    } );
    

    my $issue = $self->issue_fetch_with_rel($c, $res->{id});

    $c->render_json({ status => 1, issue => $issue });
}

sub relation_create {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $rpc_api = $c->get('API::RPC');
    my $res = $rpc_api->issue_relation_create( {
        %{ $c->request->parameters },
        author          => $member->{author},
    } );

    my $issue = $self->issue_fetch_with_rel($c, $res->{parent_issue_id});

    $c->render_json({ status => 1, issue => $issue });
}

sub relation_delete {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $id = $c->request->param('parent_issue_id');
    my $rpc_api = $c->get('API::RPC');
    my $res = $rpc_api->issue_relation_delete( {
        %{ $c->request->parameters },
        author          => $member->{author},
    } );

    my $issue = $self->issue_fetch_with_rel($c, $id);

    $c->render_json({ status => 1, issue => $issue });
}

sub attachement_create {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $id = $c->request->param('id');
    my $rpc_api = $c->get('API::RPC');
    
    my @files = $c->request->upload("file[]");
    for my $file (@files) {
        my $body;
        my $buf;
        open my $fh, '<', $file->path or die "Could not open uploaded file\n";
        while (read($fh, $buf, 1024)) {
            $body.= $buf;
        }
        close $fh;
        $body = MIME::Base64::encode_base64( $body );
        $rpc_api->issue_attachment_create( {
            issue_id   => $id,
            author     => $member->{author},
            filename   => $file->filename,
            mimetype   => $file->content_type,
            body       => $body
        });
    }

    my $issue = $self->issue_fetch_with_rel($c, $id);

    $c->render_json({ status => 1, issue => $issue });
}

sub attachement_delete {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $id = $c->request->param('issue_id');
    my $rpc_api = $c->get('API::RPC');
    $rpc_api->issue_attachment_delete( { 
        %{ $c->request->parameters },
        author => $member->{author},
    } );

    my $issue = $self->issue_fetch_with_rel($c, $id);

    $c->render_json({ status => 1, issue => $issue });
}

sub action {
    my ($self, $c) = @_;

    my $member = $self->assert_login( $c );
    return unless $member;

    my $rpc_api = $c->get('API::RPC');
    my $params = $c->request->parameters->as_hashref;
    my $slug_list = $c->request->parameters->as_hashref_multi->{slug} || [];
    my $last_checked = $c->request->param('last_checked') || '0000-00-00 00:00:00';

    my @project_id_list =  map { $_->{id} } @{ $rpc_api->project_search({
        where => {
            slug => { 'IN' => $slug_list },
        },
    }) };

    my $limit = $params->{limit} || 10;
    my $offset = $params->{offset} || 0;
    my $options = {
        order_by => 'created_on DESC',
        limit => $limit,
        offset => $offset,
    };
    my $actions = $rpc_api->issue_action_search({
        where => {
            project_id => { 'IN' => [ @project_id_list ] },
            created_on => { '>' => $last_checked },
            author => { '!=' => $member->{author} },
        },
        options => $options,
    });

    $c->render_json({ status => 1, actions => $actions });
}

no Mouse;

1;
