package Cirque::Web::Controller::Admin::Project;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller';
with 'Cirque::Trait::Controller::WithSubsession';

around qw(sync view) => sub {
    my ($next, $self, $c) = @_;
    my $stash = $c->stash;
    if (my $project = $stash->{project} ) {
        $stash->{repos} = $c->get('API::RPC')->project_repositories( { project_id => $project->{id} } );
    }
    $self->$next($c);
};

around qw(edit issues milestones sync view view_repository member_add member_delete) => sub {
    my ($next, $self, $c) = @_;
    my $member = $self->assert_login($c);
    return unless $member;

    if ( $self->load_project_by_slug($c) ) {
        $self->$next($c);
    }
};

sub index {
    my ($self, $c) = @_;

    my $api = $c->get('API::RPC');
    my $projects = $api->project_projects({});
    if ( $projects ) {
        $projects = [ sort { $a->{name} cmp $b->{name} } @$projects ];

        for my $project ( @$projects ) {
            $project->{issue_summary} = $api->issue_summarybyproject_fetch({ project_id => $project->{id} });
            unless ( $project->{issue_summary} ) {
                $project->{issue_summary} = {};
                for my $key ( qw/ total_open total_critical total_major total_minor total_nitpick total_wishlist / ) {
                    $project->{issue_summary}->{"$key"} = 0;
                }
            }
        }
    }
    $c->stash->{projects} = $projects || [];
}

sub create {
    my ($self, $c) = @_;
    if ( $c->request->method eq 'POST' ) {
        my $params = $c->request->parameters->as_hashref;
        delete $params->{repo_name};
        delete $params->{repo_url};
        my $repo_params = [];
        for my $i ( 0 .. $#{ $c->request->parameters->as_hashref_multi->{repo_name} } ) {
            push @$repo_params, {
                name => $c->request->parameters->as_hashref_multi->{repo_name}->[$i],
                url => $c->request->parameters->as_hashref_multi->{repo_url}->[$i],
                link_pattern => $c->request->parameters->as_hashref_multi->{repo_link_pattern}->[$i],
            };
        }
        my $data = { %$params, repos => $repo_params };
        my $project = $c->get('API::RPC')->project_create( $data );
        $c->render_json({ status => 1, project => $project });
        $c->finished(1);
    }
}

sub sync {
    my ($self, $c) = @_;

    my $stash   = $c->stash;
    my $project = $stash->{project};
    my $repos   = $stash->{repos};
    my $api = $c->get('API::RPC');
    $c->stash->{refresh_url} = "/admin/project/" . $project->{slug};
}

sub view {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    if ( my $project = $stash->{project}) {
        my $api = $c->get('API::RPC');
        $stash->{issue_summary} = $api->issue_summarybyproject_fetch( { project_id => $project->{id} } );
        $stash->{milestones} = $api->project_milestones( { project_id => $project->{id} } );
        my $history = $api->issue_summarybyproject_history( { 
            where => { project_id => $project->{id} },
            options => { order_by => 'logged_on DESC', limit => 20 },
        } );
        $history = $history ? $history->{history} : undef;
         
        if ( $history ) {
            $stash->{issue_summary_history} = $history;
        }
        unless ( $stash->{issue_summary} ) {
            $stash->{issue_summary} = {};
            for my $key ( qw/ open critical major minor nitpick wishlist / ) {
                $stash->{issue_summary}->{"total_$key"} = 0;
            }
        }
    }
}

sub edit {
    my ($self, $c) = @_;

    if ($c->request->method eq 'POST') {
        my $stash = $c->stash;
        my $project = $stash->{project};
 
        # XXX validation!
        $c->get('API::RPC')->project_update( {
            %{ $c->request->parameters->as_hashref },
            id => $project->{id},
        } );
        $c->redirect("/admin/project/$stash->{slug}");
    }
}

sub member_add {
    my ( $self, $c ) = @_;

    my $stash = $c->stash;
    my $project = $stash->{project};
    my $params = $c->request->parameters->as_hashref;

    $c->get('API::RPC')->project_member_add({
        project_id => $project->{id},
        account_id => $params->{account_id},
        author     => $params->{author},
    });

    $c->redirect("/admin/project/$stash->{slug}");
}

sub member_delete {
    my ( $self, $c ) = @_;

    my $stash = $c->stash;
    my $project = $stash->{project};
    my $params = $c->request->parameters->as_hashref;

    $c->get('API::RPC')->project_member_delete({
        project_id => $project->{id},
        account_id => $params->{account_id},
        author     => $params->{author},
    });

    $c->redirect("/admin/project/$stash->{slug}");
}

sub issues {
    my ($self, $c) = @_;

    my $stash   = $c->stash;
    my $project = $stash->{project};
    my $params = $c->request->parameters;
    my $resolution = $params->{resolution} || { 'NOT IN' => [ 'fixed', 'closed' ] };
    if ($resolution eq 'all') {
        undef $resolution;
    }
    
    my $sortcol = $params->{sortcol} || 'severity';
    my $sortorder = $params->{sortorder} || 'ASC';

    my %where = (
        project_id => $project->{id},
    );
    if ($resolution) {
        $where{ resolution } = $resolution;
    }
    if (my $severity = $params->{severity}) {
        # XXX multiple severity?
        $where{ severity } = $severity;
    }

    my $issues = $c->get('API::RPC')->issue_search({
        where => \%where,
        option => {
            order_by => 
                # if order by is not id, then use id as the second key to
                # sort the issues
                $sortcol ne 'id' ? 
                    sprintf('%s, id asc', join ' ', $sortcol, $sortorder) :
                    join ' ', $sortcol, $sortorder,
        }
    });
    $stash->{issues} = $issues;
}

sub milestones {
    my ($self, $c) = @_;
    my $stash = $c->stash;
    my $project = $stash->{project};
    $stash->{milestones} = $c->get('API::RPC')->project_milestones( { project_id => $project->{id} } );
}

sub view_repository {
    my ($self, $c) = @_;
    my $stash = $c->stash;
    my $match = $c->match;
    $stash->{repo} = $c->get('API::RPC')->repository_fetch({ id => $match->{repo_id} });
    $stash->{branches} = $c->get('API::RPC')->repository_branches({ id => $match->{repo_id} });
    ( $stash->{master} ) = grep { $_->{name} eq 'master' } @{ $stash->{branches} };
}

sub edit_repository {
    my ($self, $c) = @_;
    my $stash = $c->stash;
    my $match = $c->match;
    my $req   = $c->request;
    my $slug = $match->{slug};
    my $repo_id = $match->{repo_id};
    if ( $req->method eq 'POST' ) {
        $c->get('API::RPC')->repository_update({
            %{ $req->parameters->as_hashref },
            id => $repo_id,
        });
    }
    $c->redirect( "/admin/project/$slug/repository/$repo_id" );
}

sub add_repo {
    my ($self, $c) = @_;
    my $match = $c->match;
    my $params = $c->request->parameters->as_hashref;
    my $slug = $match->{slug};
    my $name = $params->{name};
    my $url = $params->{url};
    my $api = $c->get('API::RPC');

    my $project = $api->project_fetch({ slug => $slug });

    if ( $project ) {
        $api->repository_create( { name => $name, url => $url, project_id => $project->{id} } );
    }
    $c->redirect( "/admin/project/$slug" );
}

sub drop {
    my ($self, $c) = @_;
    my $match = $c->match;
    my $slug = $match->{slug};
    my $api = $c->get('API::RPC');

    my $project = $api->project_fetch({ slug => $slug });

    if ( $project ) {
        $api->project_delete({ id => $project->{id} });
    }
    $c->redirect('/admin/project');
}

no Mouse;

1;
