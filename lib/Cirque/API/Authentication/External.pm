package Cirque::API::Authentication::External;
use Cirque::Pragmas;
use Mouse;

with 'Cirque::Trait::WithContainer';

# This needs to be called for cases when actual data store is different
# from our DB.
sub initialize_member {
    my ($self, $data) = @_;

    my $email = $data->{email};

    my $api = $self->get('API::RPC');
    my ( $member ) = @{ $api->user_search({ where => { account_id => $email } }) };

    if ( $member ) {
        # nothing to do
        return;
    }

    my ( $name ) = split '@', $email;
    $api->user_create({
        name       => $name,
        account_id => $email,
        icon       => 'http://www.gravatar.com/avatar/'. Digest::MD5::md5_hex($email) .'?s=24'
    });
    $api->user_add_query({
        name       => 'Assigned Issues',
        account_id => $email,
        query      => $self->get('JSON')->encode({
            "keyword"     => [""],
            "version"     => [""],
            "reported_by" => [""],
            "project"     => [""],
            "target"      => [""],
            "resolution"  => [""],
            "assigned_to" => [$email],
            "milestone"   => [""],
        })
    });
}

no Mouse;

1;


