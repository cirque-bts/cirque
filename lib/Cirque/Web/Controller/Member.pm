package Cirque::Web::Controller::Member;
use Cirque::Pragmas;
use Mouse;
use Digest::MD5 ();

extends 'Cirque::Web::Controller';

sub view {
    my ($self, $c) = @_;
    my $stash = $c->stash;
    my $match = $c->match;
    my $api = $c->get('API::RPC');

    my $projects = $api->project_projects();
    my @project_joined;

    my $users = $api->user_search({ where => { account_id => $match->{mail} } });
    my $user = ref $users eq 'ARRAY' ?
               $users->[0] :
               { name => [split( '@', $match->{mail} )]->[0],
                 account_id => $match->{mail},
                 icon => 'http://www.gravatar.com/avatar/'. Digest::MD5::md5_hex($match->{mail}).'?s=24',
               }
    ;
    $user ||= { name => [split( '@', $match->{mail} )]->[0],
                account_id => $match->{mail},
                icon => 'http://www.gravatar.com/avatar/'. Digest::MD5::md5_hex($match->{mail}).'?s=24',
              }
    ;


    if ( $projects ) {
        for my $project ( ( @{$projects} ) ) {
            if ( grep { $_ eq $match->{mail} } @{$project->{members}} ) {
                push @project_joined, $project;
            }
            $stash->{projects} ||= {};
            $stash->{projects}->{$project->{id}} = $project;
        }
    }

    my $actions = $api->issue_action_search( {
        where => { author => $match->{mail} },
        options => {
            order_by => 'created_on DESC',
            limit => 30,
        },
    } );

    $stash->{mail} = $match->{mail};
    $stash->{project_joined} = [ @project_joined ];
    $stash->{actions} = $actions;
    $stash->{user} = $user;
    $stash->{change_password} = $user->{account_id} eq $stash->{member}->{email} && $c->get('API::Authentication')->can('change_password');
    $stash->{delete_account} = $user->{account_id} eq $stash->{member}->{email} && $c->get('API::Authentication')->can('delete_account');
}

sub edit {
    my ($self, $c) = @_;
    my $params = $c->request->parameters->as_hashref;
    my $match = $c->match;
    my $api = $c->get('API::RPC');

    my $users = $api->user_search({ where => { account_id => $match->{mail} } });
    Carp::croak('Could not find associated user') unless $users;

    $api->user_update({ id => $users->[0]->{id}, %$params });
    $c->redirect('/member/'. $match->{mail});
}

no Mouse;
1;
__END__


