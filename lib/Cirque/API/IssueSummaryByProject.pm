package Cirque::API::IssueSummaryByProject;
use Cirque::Pragmas;
use Mouse;

with qw(Cirque::API::WithTeng);

has '+primary_key' => (default => 'project_id');

sub load_history {
    my ( $self, @args ) = @_;
    my $handle = $self->get_handle('DB::Slaves');
    $handle->search( cirque_issue_summary_history => @args );
}

no Mouse;

1;
