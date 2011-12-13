package Cirque::Web::Controller::Project;
use Cirque::Pragmas;
use Mouse;

extends 'Cirque::Web::Controller';
with qw/ Cirque::Trait::Controller::WithSubsession /;

sub list {
    my ($self, $c) = @_;
    my $api = $c->get('API::RPC');
    $c->stash->{projects} = [ sort { $a->{name} cmp $b->{name} } @{ $api->project_projects } ];
}

sub view {
    my ($self, $c) = @_;
    my $params = $c->request->parameters->as_hashref;
    my $stash = $c->stash;
    my $match = $c->match;
    my $api = $c->get('API::RPC');

    my $proj = $api->project_fetch( { slug => $match->{slug} } );
    my $milestones = $api->milestone_search( { 
        where => { project_id => $proj->{id} },
        options => { order_by => 'created_on ASC' },
    } );
    my $issues;
    for my $milestone ( @$milestones ) {
        $issues = $api->issue_search( { where => { milestone_id => $milestone->{id} } } );
        $milestone->{issue_summary} = {
            count => 0,
            finished => 0,
            ratio => 0,
        };
        my $sum = $milestone->{issue_summary};
        for my $issue ( @$issues ) {
            $sum->{count} ++;
            $sum->{finished} ++ if $issue->{resolution} =~ /^(closed|fixed)$/;
        }
        $sum->{ratio} = sprintf( '%.4f', $sum->{finished} / $sum->{count} ) if $sum->{finished} && $sum->{count};
    }

    my $actions = $api->issue_action_search( {
        where => { project_id => $proj->{id} },
        options => {
            order_by => 'created_on DESC',
            limit => 30,
        },
    } );

    my $history = $api->issue_summarybyproject_history( { 
        where => { project_id => $proj->{id} },
        options => { order_by => 'logged_on DESC', limit => 20 },
    } );
    $stash->{issue_summary_history} = $history ? $history->{history} : undef;

    $stash->{project} = $proj;
    $stash->{milestones} = $milestones;
    $stash->{actions} = $actions;
    $stash->{severity} = $params->{severity};
    $stash->{resolution} = $params->{resolution};
    $stash->{fdat} = $params;
}

1;
__END__
