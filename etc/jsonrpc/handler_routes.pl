use Router::Simple::Declare;

router {
    foreach my $name ( qw(Project Issue IssueComment IssueAttachment Milestone Repository IssueSummaryByProject IssueRelation User SavedQuery ) ) {
        my $prefix = $name;
        $prefix =~ s/([a-z])([A-Z])/$1.$2/;
        $prefix = lc $prefix;
        for my $action ( qw/ create fetch update delete search / ) {
            connect "$prefix.$action" => { handler => $name,  action => $action };
        }
    }

    connect "issue.preview" => {
        handler => "Issue", action => "preview"
    };
    connect "issue_comment.preview" => {
        handler => "IssueComment", action => "preview"
    };

    foreach my $subtype ( qw(Action Attachment Comment) ) {
        my $method = sprintf "issue.%ss", lc $subtype;
        connect $method => { handler => "Issue$subtype", action => 'list' };
    }

    foreach my $action ( qw(add delete) ) {
        my $method = sprintf "project.member.%s", $action;
        connect $method => { handler => "Project", action => sprintf "member_%s", $action };
    }

    # user.add_query
    # user.update_query
    # user.del_query
    # user.saved_queries
    # user.projects
    foreach my $action ( qw(add_query update_query del_query saved_queries projects) ) {
        connect "user.$action" => {
            handler => "User",
            action  => $action
        };
    }
    connect 'user.get_notify_checked' => {
        handler => 'User',
        action => 'get_notify_checked',
    };
    connect 'user.notify_checked' => {
        handler => 'User',
        action => 'notify_checked',
    };

    connect 'project.projects' => {
        handler => 'Project',
        action => 'list',
    };
    connect 'project.milestones' => {
        handler => 'Milestone',
        action => 'load_for_project',
    };
    connect 'project.repositories' => {
        handler => 'Repository',
        action => 'list',
    };
    connect 'repository.branches' => {
        handler => 'Repository',
        action => 'branches',
    };
    connect 'repository.sync' => {
        handler => 'Repository',
        action => 'sync',
    };
    connect 'issue.set_subissues' => {
        handler => 'Issue',
        action => 'set_subissues',
    };
    connect 'issue.summarybyproject.history' => {
        handler => 'IssueSummaryByProject',
        action => 'history',
    };

    {
        my $name = 'IssueRelation';
        my $prefix = $name;
        $prefix =~ s/([a-z])([A-Z])/$1.$2/g;
        $prefix = lc $prefix;
        my $action = 'delete';
        connect "$prefix.$action" => { handler => $name,  action => $action };
    }
    
    {
        my $name = 'IssueAction';
        my $prefix = $name;
        $prefix =~ s/([a-z])([A-Z])/$1.$2/g;
        $prefix = lc $prefix;
        for my $action ( qw/ fetch search / ) {
            connect "$prefix.$action" => { handler => $name,  action => $action };
        }
    }

};
