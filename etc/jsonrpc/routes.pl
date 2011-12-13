use strict;
use Router::Simple::Declare;

router {
    connect '/rpc' =>
        { controller => 'RPC', action => 'dispatch' }, { method => 'POST' };

    connect '/attachment/view/:attachment_id' =>
        { controller => 'Attachment', action => 'view' };
};
