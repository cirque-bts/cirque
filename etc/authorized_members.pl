##
## Cirque認証アカウント設定ファイル
##
## ------------------------------------------------------------------------------------------------
## このファイルは、簡易認証機構(Cirque::API::Authentication::Simple) を利用する場合に参照されます。
##
## etc/config.plの設定項目「4.認証」にある「API::Authentication」にて、以下のような設定を行うことで
## 簡易認証機構を利用することが可能です。
##
## 'API::Authentication' => {
##     type => 'Simple',
## },
##
## 初期設定では、簡易認証機構を利用する設定となっております。
## 新規にCirqueアカウントを追加する際には、
##
## [メールアドレス] => [パスワード], 
##
## の書式で追記してください。
##
## 例: 
## {
##     'suzuki-ichiro@example.com' => 'PaS5w0Rd',
##     'sakagami-jiro@example.com' => 't0v1M@55',
## }
##

{
    'member@example.com' => 'password',
};
