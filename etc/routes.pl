use strict;
use Router::Simple::Declare;

router {
    connect '/' => { controller => 'Root', action => 'index' };
    connect qr{^/admin/project/?$} =>
        { controller => 'Admin::Project', action => 'index' };
    connect '/admin/project/create' =>
        { controller => 'Admin::Project', action => 'create' };
    connect '/admin/project/:slug/sync' =>
        { controller => 'Admin::Project', action => 'sync' };
    connect '/admin/project/:slug' =>
        { controller => 'Admin::Project', action => 'view' };
    foreach my $action ( qw(edit issues milestones add_repo drop) ) {
        connect "/admin/project/:slug/$action" =>
            { controller => 'Admin::Project', action => $action };
    }
    foreach my $action ( qw(add delete) ) {
        connect "/admin/project/:slug/member/$action" => 
            { controller => 'Admin::Project', action => "member_$action" };
    }
    connect '/admin/project/:slug/repository/:repo_id' =>
        { controller => 'Admin::Project', action => 'view_repository' };
    connect '/admin/project/:slug/repository/:repo_id/edit' =>
        { controller => 'Admin::Project', action => 'edit_repository' };

    connect '/admin/project/:slug/milestone/:milestone_id/:sid' =>
        { controller => 'Milestone', action => 'view' };
    connect '/admin/project/:slug/edit/milestone/:milestone_id' =>
        { controller => 'Milestone', action => 'edit_splash' };
    connect '/admin/project/:slug/create/milestone' =>
        { controller => 'Milestone', action => 'create_splash' };
    connect '/admin/project/:slug/create/milestone/:sid' => 
        { controller => 'Milestone', action => 'create_milestone' };

    connect '/issue/list' =>
        { controller => 'Issue', action => 'list' };
    connect '/issue/info/:issue' =>
        { controller => 'Issue', action => 'info' };
    connect '/issue/:parent_issue_id/relation/:issue_id' =>
        { controller => 'Issue', action => 'relation' };
    connect qr{^/issues/?$} =>
        { controller => 'Issue', action => 'index' };
    connect '/issues/assigned/:user_id' =>
        { controller => 'Issue', action => 'assigned' };
    connect '/issue/:issue' =>
        { controller => 'Issue', action => 'view' };
    connect '/issue/:issue/comment_preview' => 
        { controller => 'Issue', action => 'comment_preview' };
    foreach my $action ( qw(comment edit attach) ) {
        connect "/issue/:issue/$action" =>
            { controller => 'Issue', action => $action };
    }

    connect '/attachment/view/:attach_id' =>
        { controller => 'Attachment', action => 'view' };
    connect '/attachment/:attach_id/remove' =>
        { controller => 'Attachment', action => 'remove' };

    connect '/man' => 
        { controller => 'Manual', action => 'list' };
    connect '/man/:name' => 
        { controller => 'Manual', action => 'view' };

    connect '/login' =>
        { controller => 'Login', action => 'login' };
    connect '/logout' =>
        { controller => 'Login', action => 'logout' };
    
    connect '/api/login' =>
        { controller => 'API::Login', action => 'login' };
    connect '/api/project/:action' =>
        { controller => 'API::Project' };
    connect '/api/milestone/:action' =>
        { controller => 'API::Milestone' };
    connect '/api/query/:action' =>
        { controller => 'API::Query' };
    connect '/api/issue/:action' =>
        { controller => 'API::Issue' };
    connect '/api/comment/:action' =>
        { controller => 'API::Comment' };
    connect '/api/member/:action' =>
        { controller => 'API::Member' };

    connect '/member/:mail' =>
        { controller => 'Member', action => 'view' };
    connect '/member/:mail/edit' =>
        { controller => 'Member', action => 'edit' };

    connect '/issue/:id/get_related' => 
        { controller => 'Issue', action => 'get_related' };

    connect '/issue/:issue_id/comment/:comment_id/:action' => { controller => 'Issue::Comment' };


### mypage ###

    connect '/mypage' => 
        { controller => 'Root', action => 'mypage' };
    connect '/notifications' => 
        { controller => 'Root', action => 'notifications' };
    connect '/project/list' => 
        { controller => 'Project', action => 'list' };
    connect '/project/:slug' => 
        { controller => 'Project', action => 'view' };
    connect '/project/:slug/issue/report' =>
        { controller => 'Issue', action => 'report_start' };
    connect '/project/:slug/issue/preview' => 
        { controller => 'Issue', action => 'preview' };
    connect '/project/:slug/issue/confirm' =>
        { controller => 'Issue', action => 'report_confirm' };
    connect '/project/:slug/issue/:parent_issue_id/report' =>
        { controller => 'Issue', action => 'report_start' };
    connect '/project/:slug/issue/:parent_issue_id/confirm' =>
        { controller => 'Issue', action => 'report_confirm' };

};
