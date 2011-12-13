use strict;
use Router::Simple::Declare;

router {
    connect '/helloworld' => {
        controller => "HelloWorld",
        action => "index",
    };
};