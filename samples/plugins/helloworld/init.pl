Cirque::Plugin->new(
    name => "Hello World",
    on_register => sub {
        warn "hello world!";
    }
);