package Cirque::API::WithLinkExpand;
use Cirque::Pragmas;
use Mouse::Role;
use Furl::HTTP;

my $furl = Furl::HTTP->new(timeout => 3, max_redirects => 0);
sub fixup_gitlink {
    my ($self, $project, $string) = @_;

    return $string unless index($string, "git#") > -1;
    my $repos = $self->get('API::Repository')->load_by_project($project->id);

    return unless @$repos;

    $string =~ s|git#([a-fA-F0-9]{6,40})(?!#)|
        my $sha1 = $1;
        my $i = 0;
        my $string = "git#1#$sha1";

        foreach my $repo (@$repos) {
            $i++;
            my $link = $repo->link_pattern or next;
            $link =~ s/%commit/$sha1/g;
            my @res = $furl->head( $link );
            if ($res[1] eq '200') {
                $string = "git#$i#$sha1";
            }
        }
        $string;
    |ge;
    return $string;
}

no Mouse;

1;

