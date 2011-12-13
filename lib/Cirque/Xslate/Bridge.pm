package Cirque::Xslate::Bridge;
use strict;
use parent qw( Text::Xslate::Bridge );
use Text::Xslate qw( html_builder );
use Cirque::MultiMarkdown ();

__PACKAGE__->bridge(
    function => {
        markdown => html_builder {
            my $str = "\n" . shift;
            Cirque::MultiMarkdown::markdown( cirque_link("$str") );
        }
    }
);

sub cirque_link {
    my ($str) = @_;

    $str = issue_link($str);

    my $vars = Text::Xslate->current_vars;
    if (my $project = $vars->{project}) {
        $str = git_link($project, $str);
    }
    return $str;
}

sub git_link {
    my ($project, $str) = @_;

    if (length $str <= 0) {
        return;
    }

    $str =~ s/(git(?:#(\d+))?#([a-fA-F0-9]{6,40}))/format_git_link($project, $1, $2 || 1, $3 )/msge;
    $str;
}

sub format_git_link {
    my ($project, $original, $repo, $sha1) = @_;

    my $link = $project->{repositories}->[$repo - 1]->{link_pattern};
    if (! $link) {
        return $original;
    }

    $link =~ s/%commit/$sha1/g;
    return sprintf '[%s](%s)', $original, $link;
}

sub issue_link {
    my ($str) = @_;
    $str =~ s|issue#(\d+)|sprintf '[issue#%d](/issue/%d)', $1, $1|ge;
    return $str;
}

1;
