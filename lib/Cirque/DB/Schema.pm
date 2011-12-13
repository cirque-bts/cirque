package Cirque::DB::Schema;
use strict;
use Teng::Schema::Declare;

table {
    name 'cirque_servicer';
    pk 'id';
    columns qw(
        id
        name
        api_key
        api_secret
        created_on
        modified_on
    )
};

table {
    name 'cirque_project';
    pk 'id';
    columns qw(
        id
        name
        slug
        description
        enable_email
        default_assignment
        created_on
        modified_on
    );
};

table {
    name 'cirque_project_member';
    pk 'id';
    columns qw(
        id
        project_id
        account_id
    );
};

table {
    name 'cirque_milestone';
    pk 'id';
    columns qw(
        id
        project_id
        name
        due_on
        created_on
        modified_on
    );
};

table {
    name 'cirque_repository';
    pk 'id';
    columns qw(
        id
        project_id
        name
        url
        link_pattern
        created_on
        modified_on
    );
};

table {
    name 'cirque_branch';
    pk 'id';
    columns qw(
        id
        repository_id
        name
        sha1
        is_head
        created_on
        modified_on
    );
};

table {
    name 'cirque_issue';
    pk 'id';
    columns qw(
        id
        project_id
        resolution
        author
        title
        target
        issue_type
        severity
        assigned_to
        milestone_id
        version
        description
        due_on
        cc
        created_on
        modified_on
    );
};

table {
    name 'cirque_issue_action';
    pk 'id';
    columns qw(
        id
        action
        project_id
        commit_id
        issue_id
        author
        message
        reference
        metadata
        created_on
        modified_on
    );
};

table {
    name 'cirque_issue_comment';
    pk 'id';
    columns qw(
        id
        project_id
        issue_id
        author
        body
        created_on
        modified_on
    );
};

table {
    name 'cirque_issue_summary_by_project';
    pk 'project_id';
    columns qw(
        project_id
        total_open
        total_critical
        total_major
        total_minor
        total_nitpick
        total_wishlist
    );
};

table {
    name 'cirque_issue_summary_history';
    pk 'id';
    columns qw(
        id
        project_id
        total_open
        total_critical
        total_major
        total_minor
        total_nitpick
        total_wishlist
        created_on
        logged_on
    );
};

table {
    name 'cirque_issue_attachment';
    pk 'id';
    columns qw(
        id
        project_id
        issue_id
        author
        filename
        mimetype
        filesize
        body
        created_on
        modified_on
    );
};

table {
    name 'cirque_issue_relation';
    pk 'id';
    columns qw(
        id
        issue_id
        parent_issue_id
    );
};

table {
    name 'cirque_saved_query';
    pk 'id';
    columns qw(
        id
        account_id
        name
        query
        sequence
    );
};

table {
    name 'cirque_user';
    pk 'id';
    columns qw(
        id 
        account_id
        name
        icon
    );
};

table {
    name 'cirque_issue_keyword';
    pk 'id';
    columns qw(
        id
        issue_id
        keyword
    );
};

table {
    name 'cirque_user_notify_checked';
    pk 'id';
    columns qw(
        id
        account_id
        notify_checked
    );
};

1;
