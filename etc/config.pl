{
##
## config.pl
## Cirqueの動作設定ファイル
##

## ================================================================================================
## 1. 各サーバのバインドポート設定
##

# -------------------------------------------------------------------------------------------------
# Runner - 各サーバのバインドポートの設定
#
# Webapp, JSONRPCのそれぞれについて、バインドポートを設定します。
#
    'Runner' => {
        Webapp => {
            listen => sprintf('%s:%s', 
                $ENV{CIRQUE_WEB_LISTEN_HOST} || '127.0.0.1',
                $ENV{CIRQUE_WEB_LISTEN_PORT} || 5000
            ),
        },
        JSONRPC => {
            listen => sprintf('%s:%s',
                $ENV{CIRQUE_JSONRPC_LISTEN_HOST} || '127.0.0.1',
                $ENV{CIRQUE_JSONRPC_LISTEN_PORT} || 8080
            ),
        },
    },


## ================================================================================================
## 2. データベース
##

# -------------------------------------------------------------------------------------------------
# DB::Master - データベース接続の設定
#
# 書き込み先となるデータベースの接続情報です。
# connect_infoにDBI->connect()の引数と同様の指定が可能です。
#
    'DB::Master' => {
        connect_info  => [ 
            $ENV{ CIRQUE_MYSQL_DSN } || 'dbi:mysql:dbname=cirque;sql-mode=STRICT_TRANS_TABLES',
            $ENV{ CIRQUE_MYSQL_USERNAME } || 'root', 
            $ENV{ CIRQUE_MYSQL_PASSWORD } || undef,
            {
                RaiseError => 1,
                AutoCommit => 1,
                mysql_enable_utf8 => 1,
            },
        ],
    },


## ================================================================================================
## 3. JSON-RPC関連設定
##

# -------------------------------------------------------------------------------------------------
# RPC::Client - WebappがJSON-RPCを利用するうえで必要な認証設定
#
# api_key, api_secret それぞれに、cirqueadminコマンドで発行された値を設定する必要があります。
#
    'RPC::Client' => { 
        eval { %{ require( path_to( 'etc', 'jsonrpc_credentials.pl' ) ) } },
        url => $ENV{ CIRQUE_JSONRPC_URL } ||
            sprintf( 'http://127.0.0.1:%d/rpc', ($ENV{CIRQUE_JSONRPC_LISTEN_PORT } || 8080) ),
    },

    JSONRPC => {
        # JSONRPCで認証を有効にするには、下記に1を指定する
        authenticate => $ENV{ JSONRPC_AUTHENTICATION }
    },

# -------------------------------------------------------------------------------------------------
# JSONRPC::Router - JSON-RPCのルーティング設定
#
# Router::Simpleオブジェクトを返すファイルを指定します。
# 通常、この設定項目を設定/変更する必要はありません。
#
#    'JSONRPC::Router' => {
#        routes => path_to('etc', 'jsonrpc', 'routes.pl'),
#    },

# -------------------------------------------------------------------------------------------------
# JSONRPC::Handler::Router - JSON-RPCハンドラのルーティング設定
#
# Router::Simpleオブジェクトを返すファイルを指定します。
# 通常、この設定項目を設定/変更する必要はありません。
#
#    'JSONRPC::Handler::Router' => {
#        routes => path_to('etc', 'jsonrpc', 'handler_routes.pl'),
#    },


## ================================================================================================
## 4. 認証
##

# -------------------------------------------------------------------------------------------------
# API::Authentication - Authentication backend
#
# Choose what type of authentication backend you're using. Default is "Simple". 
#
# "Simple" specific configuration will be placed under
# "API::Authentication::Simple" entry elsewhere in this config.
#
    'API::Authentication' => {
        type => 'Simple',
    },

# -------------------------------------------------------------------------------------------------
# API::Authentication::Simple - 簡易認証バックエンド
#
# ここで設定された値は、Cirque::API::Authentication::Simpleのコンストラクタ引数として利用されます。
# membersには、Cirqueを利用するメンバーのメールアドレスをキーとしたハッシュの形式で、各メンバーの
# パスワードを指定する必要があります。
# デフォルトでは、etc/authorized_members.plの内容を参照する設定となっています。
#
    'API::Authentication::Simple' => {
        members => require( path_to( 'etc', 'authorized_members.pl' ) ),
    },


## ================================================================================================
## 5. メール関連設定
##

# -------------------------------------------------------------------------------------------------
# API::Email - メール送信サーバ及びエンコーディング関連の設定
#
# sender: Email::Sendのコンストラクタ引数を渡すことが可能です。
# encodings: subject/bodyともにEncode.pmで利用可能なエンコーディングを指定できます。
# add_headers: HashRefでメールのヘッダを設定できます。
#
    'API::Email' => {
        sender => {
            mailer => 'Sendmail',
        },
        encodings => {
            subject => 'MIME-Header-ISO_2022_JP',
            body    => 'iso-2022-jp',
        },
        add_headers => {
            'Content-Type' => 'text/plain; charset=ISO-2022-JP',
        },
    },

# -------------------------------------------------------------------------------------------------
# Email::Template - 通知メールのテンプレート設定
#
# 通知メールのテンプレートファイルの置き場所やテンプレート形式の指定項目です。
# Text::Xslateで利用できるオプションをそのまま設定できます。
#
    'Email::Template' => {
        path => [
            path_to( 'view', 'mail' ),
        ],
        syntax => 'TTerse',
        type => 'text',
    },


## ================================================================================================
## 6. 多言語対応設定
##

# -------------------------------------------------------------------------------------------------
# Localizer - 多言語対応のためのマッピング設定
#
# Localizer.localizersには、Data::Localize->add_localize()引数相当のHashRefを含んだ
# ArrayRefを設定できます。
#
    'Localizer' => {
        localizers => [
            {
                class => 'Gettext',
                paths => [ path_to("etc/gettext/*.po") ],
            }
        ]
    },


## ================================================================================================
## 7. バリデータ設定
##

# -------------------------------------------------------------------------------------------------
# Validator - バリデーション処理に利用されるプロファイル設定
#
# Validator.profilesには、Cirque::DFVを使用したプロファイル設定ファイルを指定します。
# 通常、この設定値を変更する必要はありません。
#
#    'Validator' => {
#        profiles => path_to("etc", "profiles.pl"),
#    },

## ================================================================================================
## 8. Webルーティング設定
##

# -------------------------------------------------------------------------------------------------
# Web::Router - Webappのルーティング設定
#
# Router::Simpleオブジェクトを返すファイルを指定します。
# 通常、この設定項目を設定/変更する必要はありません。
#
#    'Web::Router' => {
#        routes => path_to('etc', 'routes.pl'),
#    },


## ================================================================================================
## 9. Webテンプレート設定
##

# -------------------------------------------------------------------------------------------------
# Web::View::Xslate - Webappのテンプレート設定
#
# Webappのテンプレートファイルの置き場所やテンプレート形式の指定項目です。
# Text::Xslateで利用できるオプションをそのまま設定できます。
# 通常、この設定項目を設定/変更する必要はありません。
#
    'Web::View::Xslate' => {
        path => [
            path_to('view'),
            path_to('view', 'include'),
        ],
        syntax => 'TTerse',
        module => [ 'Cirque::Xslate::Bridge', 'Text::Xslate::Bridge::TT2Like' ],
    },


## ================================================================================================
## 10. フック設定
##

# -------------------------------------------------------------------------------------------------
# Worker::Hook - 任意のフックを登録
#
# endpoint_map に、フック通知をさせたいタイミングと通知先を指定できます。
# 通知タイミングはRegexpRefで指定し、通知先はArrayRefで通知先モジュールを複数指定します。
# 通知タイミングには以下のものがあります。
#     - issue.create : イッシュー新規作成時
#     - issue.comment : イッシューへのコメント追加時
#     - issue.edit : イッシュー編集時
#     - issue.attach : イッシューへの添付ファイル追加時
#     - issue.remove_attach : イッシューからの添付ファイル削除時
# また通知先には、後述のWorker::Notify::Handler内のendpointsで設定されているキーを複数指定できます。
# デフォルトでは、イッシューの新規作成時およびコメント追加時にメール送信を行いかつ、ikachan(IRC-bot)
# で通知を行う設定になっています。
#
# endpointsに、通知データを受け取るプログラムを指定できます。
# 通知データはJSON形式で標準入力から読み取ることが可能です。
    'API::Hook' => {
        # 通知先の設定
        # 文字列の場合は実行されるファイル名として解釈され、
        # CodeRefの場合は指定された関数が実行されます
        endpoints => { 
            mail => path_to( 'hooks', 'email' ),
            ikachan => path_to( 'hooks', 'ikachan' ),
        },
        # 任意のタイミングに通知先を指定
        endpoint_map => [
            qr/^issue\.(create|comment)$/ => [
                'mail',
                'ikachan',
            ],
        ]
    },
};
