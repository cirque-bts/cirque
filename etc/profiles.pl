use strict;

use Data::FormValidator::Constraints qw/ email /;
use Cirque::DFV::Filters::HTMLScrubber qw/ html_scrub /;
use Date::Calc qw/ check_date check_time /;

my $v = {
    Resolution  => qr/^(?:open|in-progress|verify-fixed|fixed|wontfix|dup|closed)$/,
    IssueType   => qr/^(?:bug|feature|improvement|wishlist)$/,
    Severity    => qr/^(?:critical|major|minor|nitpick|wishlist)$/,
    Int         => qr/^\-?\d+$/,
    PositiveInt => qr/^\d+$/,
    Slug        => qr/^[A-Za-z0-9][A-Za-z0-9_\-]+$/,
    AccountLike => qr/^[A-Za-z][A-Za-z0-9_\-]+$/,
    Email       => sub {
                       unless( email()->(@_) ) {
                           $_[0]->set_current_constraint_name("error.invalid");
                           return;
                       }
                       return 1;
                   },
    URI         => sub {
                       return 1 if $_[1] =~ /^.+?\:\/\/.+/;
                       return 1 if $_[1] =~ /^git@.+\:.+$/;
                   },
    Str         => sub { length $_[1] > 0 }, 
    Datetime    => sub {
                       my ( $dfv, $str ) = @_;
                       return unless $str =~ /^(\d{1,4})\-(\d{1,2})\-(\d{1,2}) (\d{1,2}):(\d{1,2}):(\d{1,2})$/;
                       my ( $year, $mon, $day, $hour, $min, $sec ) = ( $1, $2, $3, $4, $5, $6 );
                       return unless check_date( $year, $mon, $day ) && check_time( $hour, $min, $sec );
                       return 1;
                   },
    Any         => sub { 1 },
};

sub arg($) { 
    my $args = shift;
    my $rtn = {};
    my $type;
    for my $col ( keys %$args ) {
        $type = $args->{$col} or die "Not exists such field";
        $rtn->{$col} = ref $type eq 'CODE' ? $type : 
                       ref $type eq 'Regexp' ? $type : 
                       $v->{$type};
    }
    return $rtn;
}

sub typeas($&) {
    my ( $type, $extend_constraint ) = @_;
    my $constraint = $v->{ $type };
    return sub {
        my ( $dfv, $str ) = @_;
        return unless $constraint->( $dfv, $str );
        return unless $extend_constraint->( $dfv, $str );
    };
}

return {
    fetch_project => {
        require_some => {
            id_or_slug => [ 1, qw(id slug) ]
        },
    },
    delete_project => {
        required =>  [ qw(id) ],
    },
    create_project => {
        required => [qw/ name slug /],
        optional => [qw/ description repos enable_email default_assignment /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
            description => [ html_scrub() ],
        },
        constraint_methods => arg {
            name        => 'Str',
            slug        => 'Slug',
            description => 'Any',
            repos       => sub { ref $_[1] eq 'HASH' },
        },
    },
    update_project => {
        required => [qw/ id /],
        optional => [qw/ name slug description enable_email default_assignment /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
            description => [ html_scrub() ],
        },
        constraint_methods => arg {
            id          => 'Str',
            name        => 'Str',
            slug        => 'Slug',
            description => 'Any',
        },
        missing_optional_valid => 0,
    },
    fetch_milestone => {
        required => [ qw(id) ],
    },
    delete_milestone => {
        required =>  [ qw(id) ],
    },
    create_milestone => {
        required => [qw/ project_id name /],
        optional => [qw/ due_on /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
        },
        constraint_methods => arg {
            project_id => 'Str',
            name       => 'Str',
            due_on     => 'Datetime',
        },
    },
    update_milestone => {
        required => [qw/ id /],
        optional => [qw/ name due_on /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
        },
        constraint_methods => arg {
            id         => 'PositiveInt',
            name       => 'Str',
            due_on     => 'Datetime',
        },
        missing_optional_valid => 0,
    },
    create_repository => {
        required => [qw/ project_id name url /],
        optional => [qw/ link_pattern /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
        },
        constraint_methods => arg {
            project_id => 'Str',
            name       => 'Str',
            url        => 'URI',
            link_pattern => 'Str',
        },
    },
    update_repository => {
        required => [qw/ id /],
        optional => [qw/ name url link_pattern /],
        filters => 'trim',
        field_filters => {
            name => [ html_scrub() ],
        },
        constraint_methods => arg {
            id         => 'Str',
            name       => 'Str',
            url        => 'URI',
            link_pattern => 'Str',
        },
        missing_optional_valid => 0,
    },
    fetch_issue => {
        required => [ qw(id) ]
    },
    delete_issue => {
        required =>  [ qw(id) ],
    },
    create_issue => {
        required => [qw/ project_id author title issue_type description severity /],
        optional => [qw/ target assigned_to version milestone_id due_on resolution parent_issue_id cc /],
        constraint_methods => arg {
            project_id   => sub {
                my ($dfv, $project_id) = @_;
                return unless defined $project_id;
                return !!$dfv->container->get('API::Project')->find($project_id);
            },
            resolution   => 'Resolution',
            author       => 'Email',
            title        => 'Str',
            target       => 'Str',
            issue_type   => 'IssueType',
            severity     => 'Severity',
            assigned_to  => 'Email',
            version      => 'Str',
            due_on       => 'Datetime',
            milestone_id => 'Int',
            description  => 'Any',
            parent_issue_id => 'Int',
        },
    },
    update_issue => {
        required => [qw/ id author /],
        optional => [qw/ resolution title issue_type description target severity assigned_to version milestone_id due_on parent_issue_id cc /],
        constraint_methods => arg {
            id           => 'Int',
            author       => 'Email',
            resolution   => 'Resolution',
            title        => 'Str',
            target       => 'Str',
            issue_type   => 'IssueType',
            severity     => 'Severity',
            assigned_to  => 'Str',
            version      => 'Str',
            due_on       => 'Datetime',
            milestone_id => 'Int',
            description  => 'Any',
            parent_issue_id => 'Int',
            cc           => 'Str',
        },
    },
    create_issue_relation => {
        required => [qw/ issue_id parent_issue_id /],
        constraint_methods => arg {
            issue_id        => 'Int',
            parent_issue_id => 'Int',
        },
    },
    delete_issue_relation => {
        required => [qw/ issue_id parent_issue_id /],
        constraint_methods => arg {
            issue_id        => 'Int',
            parent_issue_id => 'Int',
        },
    },
    fetch_issue_relation => {
        required => [qw/ id /],
    },
    issue_comments => {
        required => [qw/ issue_id /],
        constraint_methods => arg {
            issue_id => 'Int',
        },
    },
    fetch_issue_comment => {
        required => [qw/ id /],
        constraint_methods => arg {
            id => 'Int',
        },
    },
    create_issue_comment => {
        required => [qw/ issue_id project_id author body /],
        optional => [qw/ commit_id /],
        constraint_methods => arg {
            project_id => 'Str',
            issue_id   => 'Int',
            author     => 'Email',
            body       => 'Str',
            commit_id  => 'Str',
        },
    },
    update_issue_comment => {
        required => [qw/ id author body /],
        optional => [qw/ issue_id project_id commit_id /],
        constraint_methods => arg {
            id         => 'Int',
            project_id => 'Str',
            issue_id   => 'Int',
            author     => 'Email',
            body       => 'Str',
            commit_id  => 'Str',
        },
    },
    create_issue_attachment => {
        required => [qw/ issue_id body filename mimetype author /],
        constraint_methods => arg {
            issue_id => 'Int',
            body     => 'Any',
            filename => 'Str',
            mimetypr => 'Str',
            author   => 'Email',
        },
    },
    fetch_issue_attachment => {
        required => [qw/ id /],
        constraint_methods => arg {
            id => 'Int',
        },
    },
    delete_issue_attachment => {
        required => [qw/ id /],
        constraint_methods => arg {
            id => 'Int',
        },
    },
    fetch_issue_action => {
        required => [qw/ id /],
        constraint_methods => arg {
            id => 'Int',
        },
    },
    fetch_repository => {
        required => [qw/ id /],
        constraint_methods => arg {
            id => 'Str',
        },
    },
    add_project_member => {
        required => [qw/ project_id account_id author /],
        constraint_methods => arg {
            project_id => 'Str',
            account_id => 'Email',
            author     => 'Email',
        },
    },
    delete_project_member => {
        required => [qw/ project_id account_id author /],
        constraint_methods => arg {
            project_id => 'Str',
            account_id => 'Email',
            author     => 'Email',
        },
    },
    create_user => {
        required => [qw/ account_id name /],
        optional => [qw/ icon /],
    },
    update_user => {
        required => [qw/ id /],
        optional => [qw/ account_id name icon /],
    },
    fetch_user => {
        optional => [qw/ id account_id /],
    },
    delete_user => {
        required => [qw/ id /],
    },
    fetch_saved_query => {
        required => [qw/ id /],
    },
    update_saved_query => {
        required => [qw/ id /],
        optional => [qw/ query name sequence account_id /],
    },
    auth_add_account => {
        required => [qw/ account password /],
        constraint_methods => arg {
            account => 'Email',
            password => 'Str',
        },
    },
    auth_change_password => {
        required => [qw/ account password /],
        constraint_methods => arg {
            account => 'Email',
            password => 'Str',
        },
    },
    auth_delete_account => {
        required => [qw/ account /],
        constraint_methods => arg {
            account => 'Email',
        },
    },
};


