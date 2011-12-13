use strict;
use Cirque::Pragmas;
use t::Util qw(create_ctxt assert_email_count);
use Cirque::Util qw(random_ascii_string);
use Cirque::API::Hook;
use JSON;
use Test::More;
use Test::Fatal;

my $ctxt = create_ctxt();
my $proj = $ctxt->get('API::Project')->create( {
    name => random_ascii_string 12,
    slug => random_ascii_string 10,
    repos => [
        { url => "http://foobar.example.com/member_test.git", name => 'repo0' },
    ]
});
END {
    eval {
        $ctxt->get('API::Project')->delete({ id => $proj->id } );
    };
}

subtest 'basic' => sub {
    my $issue = $ctxt->get('API::Issue')->create({
        project_id => $proj->id,
        title => "テスト",
        description => "ワーカーテスト",
        author => 'test@bts.example.com',
        issue_type => 'bug',
    });
    my ($assoc_action) = $ctxt->get('API::IssueAction')->search( { issue_id => $issue->id } );

    my $called = 0;
    my $hook = Cirque::API::Hook->new(
        endpoint_map => [
            "issue.create" => [ "dummy" ],
        ],
        endpoints => {
            dummy => sub {
                my $json = do { local $/; scalar <STDIN> };
                my $action;
                is exception { 
                    $action = decode_json $json;
                }, undef, "JSON parsed OK: $@";
                note explain $action;

                is $action->{action}, $assoc_action->action, "action matches";
                is $action->{author}, $issue->author, "author matches";
                like $action->{message}, qr/added issue '.+'/, "message matches";
                is $action->{project}->{id}, $proj->id, "project id matches";
                is $action->{issue}->{id}, $issue->id, "issue id matches";
                $called++;
            }
        },
        container => $ctxt->container,
    );

    $hook->process( { action => $assoc_action->id } );

    is $called, 1, "only called once";
};

done_testing;
