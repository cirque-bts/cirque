use strict;
use Test::More;

use_ok "Text::Xslate";
use_ok "Cirque::Xslate::Bridge";

sub make_xslate {
    my $t = Text::Xslate->new(
        module => [ "Cirque::Xslate::Bridge" ],
        syntax => "TTerse",
    );
}

subtest 'git link' => sub {
    my $t = make_xslate();
    my $text = <<'EOM';
Markdown is here.

This is a link to git commit git#abcdef0123456789abcdef012345689abcdef012
EOM

    my $rendered = $t->render_string( '[% text | markdown %]', {
        text => $text,
        project => {
            repositories => [
                { url => "git://github.com/user/foobar.git",
                  link_pattern => "https://github.com/user/foobar/commit/%commit"
                }
            ]
        }
    } );

    is $rendered, <<'EOM', "rendered text matches";
<p>Markdown is here.</p>

<p>This is a link to git commit <a href="https://github.com/user/foobar/commit/abcdef0123456789abcdef012345689abcdef012">git#abcdef0123456789abcdef012345689abcdef012</a></p>
EOM
};

subtest 'git link (short)' => sub {
    my $t = make_xslate();
    my $text = <<'EOM';
Markdown is here.

This is a link to git commit git#abcdef

git#1#0123456

git#2#0123abc
EOM

    my $rendered = $t->render_string( '[% text | markdown %]', {
        text => $text,
        project => {
            repositories => [
                { url => "git://github.com/user/foobar.git",
                  link_pattern => "https://github.com/user/1/commit/%commit"
                },
                { url => "git://github.com/user/foobar.git",
                  link_pattern => "https://github.com/user/2/commit/%commit"
                },
                { url => "git://github.com/user/foobar.git",
                  link_pattern => "https://github.com/user/3/commit/%commit"
                },
            ]
        }
    } );

    is $rendered, <<'EOM', "rendered text matches";
<p>Markdown is here.</p>

<p>This is a link to git commit <a href="https://github.com/user/1/commit/abcdef">git#abcdef</a></p>

<p><a href="https://github.com/user/1/commit/0123456">git#1#0123456</a></p>

<p><a href="https://github.com/user/2/commit/0123abc">git#2#0123abc</a></p>
EOM
};

subtest 'issue link' => sub {
    my $t = make_xslate();
    my $text = <<'EOM';
Markdown is here.

This is a link to an issue issue#100
EOM

    my $rendered = $t->render_string( <<'EOM', { text => $text } );
[% text | markdown %]
EOM

    is $rendered, <<'EOM', "rendered text matches";
<p>Markdown is here.</p>

<p>This is a link to an issue <a href="/issue/100">issue#100</a></p>

EOM
};

done_testing;