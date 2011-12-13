package Cirque::JSONRPC::Controller::RPC;
use Cirque::Pragmas;
use Mouse;
use Plack::Request;
use Plack::TempBuffer;

extends qw/ Cirque::JSONRPC::Controller /;

use constant LOGGING => $ENV{CIRQUE_JSONRPC_LOGGING};

sub dispatch {
    my ( $self, $c ) = @_;

    my $req = $c->request;
    my $header = $req->headers;
    my $coder = $c->get('JSON');

    my $servicer; # dummy
    my $authenticated = 0;
    if ( ! $c->config->{JSONRPC}->{authenticate} ) {
        $authenticated = 1;
    } else {
        my $credential = {
            api_key    => delete $header->{'x-cirque-auth.api-key'} || '',
            api_secret => delete $header->{'x-cirque-auth.api-secret'} || '',
        };

        if ( ! $credential->{api_key} ) {
            # XXX [後方互換] Handlerで処理していた時はparamsにauth情報を入れていたので、
            # headerになければcontent内のjsonから抽出した値を参照する。その後、
            # auth情報を取り除いたcontent内のjsonを$req->contentで読めるようにしている
            my $content = $coder->decode($req->content);
            $credential = {
                api_key => delete $content->{params}->{'auth.api_key'} || '',
                api_secret => delete $content->{params}->{'auth.api_secret'} || '',
            };

            my $json_content = $coder->encode($content);
            my $cl = $self->{env}->{'CONTENT_LENGTH'} = length $json_content;
            my $buffer = Plack::TempBuffer->new($cl);
            $buffer->print($json_content) if $buffer;
            $req->{env}->{'psgi.input'} = $buffer->rewind;
        }

        $servicer = $self->_authenticate( $credential, $c );
        if ($servicer) {
            $authenticated = 1;
        }
    }


    ### LOGGING
    # disable
    if ( 0 ) {
        my $procedure = $coder->decode($req->content);
        my $time = localtime->strftime("%Y-%m-%d %H:%M:%S");
        my $params = $coder->encode($procedure->params);
        my $action = $procedure->action;
        my $real_action = $servicer ? $action : "auth_error";
        my $servicer_id = $servicer ? $servicer->id : 'unknown';
        warn sprintf "[JSONRPC]\t%s\t%s\t%s\t%s\t%s(%s)\t%s\n", $time, $procedure->id, $servicer_id, ref $self, $action, $real_action, $params;
    }

    if( $authenticated ){
        my $res = $c->get('JSONRPC::Handler::Dispatcher')->handle_psgi( $c->request, $c );
        for my $field ( qw/ status headers body / ) {
            $c->response->$field( $res->$field );
        }
    } else {
        $self->_auth_error( undef, $c );
    }

    $c->finished( 1 );
}

sub _authenticate {
    my ( $self, $credential, $c ) = @_;
    my $api = $c->get('API::Servicer');
    my ( $servicer ) = $api->search( $credential );
    return $servicer;
}

sub _auth_error {
    my ( $self, $credential, $c ) = @_;
    my $json = { error => { message => "Authorization Failure"} };
    my $res = $c->response;
    $res->content_type('application/json');
    $res->body( $c->get('JSON')->encode( $json ) );

    $c->finished(1);
}

no Mouse;

1;
__END__

