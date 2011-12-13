package Cirque::Web::Controller::API::Project;
use Cirque::Pragmas;
use Mouse;
use Time::Piece;

extends 'Cirque::Web::Controller::API';

sub list {
    my ($self, $c) = @_;

    my $projects = $c->get('API::RPC')->project_projects({});
    
    # for my $project (@{$projects}) {
    #     my $milestones =
    #         $c->get('API::RPC')->project_milestones( { project_id => $project_id } );
    # 
    #     for my $milestone (@$milestones) {
    #         my $name = $milestone->{name};
    #         $milestone->{name} = decode_utf8($milestone->{name});
    #     }
    # }
    
    $c->render_json({ status => 1, projects => $projects });
}

sub issue_summary_history {
    my ( $self, $c ) = @_;

    my $api = $c->get('API::RPC');
    my $params = $c->request->parameters;

    my $proj = $api->project_fetch( { slug => $params->{slug} } );

    my $data ;

    if ( $proj ) {
        my $history = $api->issue_summarybyproject_history( { 
            where => { project_id => $proj->{id} },
            options => { order_by => 'logged_on DESC', limit => 20 },
        } );
        $data = $history ? $history->{history} : undef;
         if ( $data ) {
             if ( scalar @{$data->{logged_on}} > 0 ) {
                 my $pos_base = Time::Piece->strptime( $data->{logged_on}->[$#{$data->{logged_on}}], '%Y-%m-%d %H:%M:%S' )->strftime('%s');
                 my $pos_max = Time::Piece->strptime( $data->{logged_on}->[0], '%Y-%m-%d %H:%M:%S' )->strftime('%s') - $pos_base;
                 $data->{position} = [ 
                     map { 
                         my $x = ( Time::Piece->strptime( $_, '%Y-%m-%d %H:%M:%S' )->strftime('%s') - $pos_base );
                         $x ? sprintf( '%.4f', $x / $pos_max  ) : 0 ;
                     } @{$data->{logged_on}}
                 ] ;
             }
             for my $key ( keys %$data ) {
                 $data->{$key} = [ reverse @{$data->{$key}} ];
             }
         }
    }

    $c->render_json({
        status => 1, 
        data   => $data,
    });
}

no Mouse;

1;
