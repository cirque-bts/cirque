package Cirque::JSONRPC::Handler::IssueSummaryByProject;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::JSONRPC::Handler::CRUD /;

override fetch => sub {
    my ( $self, $params, $procedure, $c ) = @_;
    my $api = $c->get('API::IssueSummaryByProject');
    my $row = $api->find( $params->{project_id} );
    return $row->get_columns if defined $row;
};

sub history {
    my ( $self, $params, $procedure, $c ) = @_;
    $params->{options}->{limit} ||= 10;
    $params->{options}->{limit} = $params->{options}->{limit} > 50 ? 50 : $params->{options}->{limit} ;
    my $api = $c->get('API::IssueSummaryByProject');
    my $rows = [ map { $_ = $_->get_columns } $api->load_history( $params->{where}, $params->{options} ) ];
    my $history = {};
    for my $row ( @$rows ) {
        $history->{logged_on} ||= [];
        push @{ $history->{logged_on} }, $row->{logged_on};
        for my $severity ( qw/ open critical major minor nitpick wishlist / ) {
            $history->{$severity} ||= [];
            push @{ $history->{$severity} }, $row->{"total_$severity"};
        }
    }
    return { history => $history };
}

no Mouse;

1;
__END__
