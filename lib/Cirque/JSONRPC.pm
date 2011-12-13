package Cirque::JSONRPC;
use Cirque::Pragmas;
use Mouse;

extends qw/ Cirque::WAF /;

no Mouse;

1;

__END__

=head1 Available JSON-RPC Procedures

=head2 project.projects

プロジェクト一覧を取得します。

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "projects" : "..."
       }
    }

=over 4

=item projects

プロジェクトのリスト

=back

=head2 project.create

プロジェクトを新規作成します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "description" : "...",
          "name" : "...",
          "slug" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

作成者メールアドレス

=item description (Str, required)

プロジェクト詳細

=item name (Str, required)

プロジェクト名

=item slug (Str, required)

省略名 (URLに使用)

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

作成されたプロジェクトID

=back

=head2 project.update

既存プロジェクトを変更します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "description" : "...",
          "id" : "...",
          "name" : "...",
          "slug" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

変更者メールアドレス

=item description (Str, optional)

プロジェクト詳細

=item id (Str, required)

プロジェクトID

=item name (Str, optional)

プロジェクト名

=item slug (Str, optional)

省略名 (URLに使用)

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

変更されたプロジェクトID

=back

=head2 project.fetch

既存プロジェクト情報を取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "...",
          "slug" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Str, optional)

プロジェクトID (slugが無い場合は必須)

=item slug (Str, optional)

プロジェクト省略名 (idが無い場合は必須)

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "created_on" : "...",
          "description" : "...",
          "id" : "...",
          "members" : "...",
          "modified_on" : "...",
          "name" : "...",
          "repositories" : "...",
          "slug" : "..."
       }
    }

=over 4

=item created_on

登録日時

=item description

説明文

=item id

プロジェクトID

=item members

プロジェクトメンバーのリスト

=item modified_on

情報更新日時

=item name

プロジェクト名

=item repositories

レポジトリIDの配列

=item slug

省略名

=back

=head2 project.milestones

既存プロジェクトに登録されているマイルストーンリストを取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "project_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item project_id (Str, required)

プロジェクトID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "milestones" : "..."
       }
    }

=over 4

=item milestones

マイルストーンのリスト

=back

=head2 project.repositories

既存プロジェクトに登録されているレポジトリリストを取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "project_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item project_id (Str, required)

プロジェクトID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "repositories" : "..."
       }
    }

=over 4

=item repositories

レポジトリのリスト

=back

=head2 repository.branches

既存レポジトリに登録されているブランチリストを取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Str, required)

レポジトリID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "branches" : "..."
       }
    }

=over 4

=item branches

ブランチのリスト

=back

=head2 repository.sync

既存レポジトリの同期を行います

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Str, required)

レポジトリID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 repository.create

既存プロジェクトに新規レポジトリを追加します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "name" : "...",
          "project_id" : "...",
          "url" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item name (Str, required)

レポジトリ名

=item project_id (Str, required)

プロジェクトID

=item url (Str, required)

レポジトリURL

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

新規レポジトリID

=back

=head2 repository.fetch

既存レポジトリの情報を取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Str, required)

レポジトリID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "created_on" : "...",
          "id" : "...",
          "modified_on" : "...",
          "name" : "...",
          "project_id" : "...",
          "url" : "..."
       }
    }

=over 4

=item created_on

登録日時

=item id

レポジトリID

=item modified_on

情報更新日時

=item name

レポジトリ名

=item project_id

プロジェクトID

=item url

レポジトリURL

=back

=head2 repository.update

既存レポジトリの情報を変更します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "...",
          "name" : "...",
          "url" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)

レポジトリID

=item name (Str, optional)

レポジトリ名

=item url (Str, optional)

レポジトリURL

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

変更対象のレポジトリID

=back

=head2 repository.delete

既存レポジトリを削除します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)

レポジトリID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 issue.create

新規イッシューを作成します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "assigned_to" : "...",
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "cc" : "...",
          "description" : "...",
          "due_on" : "...",
          "issue_type" : "...",
          "milestone_id" : "...",
          "parent_issue_id" : "...",
          "project_id" : "...",
          "resolution" : "...",
          "severity" : "...",
          "target" : "...",
          "title" : "...",
          "version" : "..."
       }
    }

=over 4

=item assigned_to (Str, optional)

担当者（メールアドレス)

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

作成者メールアドレス

=item cc (Str, optional)

通知先CC(カンマ区切りで複数入力)

=item description (Str, required)

概要・説明

=item due_on (Datetime, optional)

締め切り日

=item issue_type (ENUM(bug,feature,improvement,wishlist), required)

イッシュー種別

=item milestone_id (Int, optional)

マイルストーンID

=item parent_issue_id (Int, optional)

親イッシューID

=item project_id (Str, required)

プロジェクトID

=item resolution (ENUM(open,in-progress,fixed,wontfix,dup,closed), optional)

状態 (デフォルト 'open')

=item severity (ENUM(critical,major,minor,nitpick,wishlist), required)

イッシュー重要度

=item target (Str, optional)

修正対象コンポーネント

=item title (Str, required)

タイトル

=item version (Str, optional)

修正対象バージョン

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

作成されたイッシューID

=back

=head2 issue.update

既存イッシューを変更します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "assigned_to" : "...",
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "cc" : "...",
          "description" : "...",
          "due_on" : "...",
          "id" : "...",
          "issue_type" : "...",
          "milestone_id" : "...",
          "parent_issue_id" : "...",
          "project_id" : "...",
          "resolution" : "...",
          "severity" : "...",
          "target" : "...",
          "title" : "...",
          "version" : "..."
       }
    }

=over 4

=item assigned_to (Str, optional)

担当者（メールアドレス)

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

変更者メールアドレス

=item cc (Str, optional)

通知先CC(カンマ区切りで複数入力)

=item description (Str, optional)

概要・説明

=item due_on (Datetime, optional)

締め切り日

=item id (Int, required)

変更したいイッシューのID

=item issue_type (ENUM(bug,feature,improvement,wishlist), optional)

イッシュー種別

=item milestone_id (Int, optional)

マイルストーンID

=item parent_issue_id (Int, optional)

親イッシューID

=item project_id (Str, optional)

プロジェクトID

=item resolution (ENUM(open,in-progress,fixed,wontfix,dup,closed), optional)

状態 (デフォルト 'open')

=item severity (ENUM(critical,major,minor,nitpick,wishlist), optional)

イッシュー重要度

=item target (Str, optional)

修正対象コンポーネント

=item title (Str, optional)

タイトル

=item version (Str, optional)

修正対象バージョン

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

変更されたイッシューID

=back

=head2 issue.fetch

既存イッシューを取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)

取得したいイッシューのID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "assigned_to" : "...",
          "cc" : "...",
          "description" : "...",
          "due_on" : "...",
          "id" : "...",
          "issue_type" : "...",
          "milestone_id" : "...",
          "project_id" : "...",
          "resolution" : "...",
          "severity" : "...",
          "target" : "...",
          "title" : "...",
          "version" : "..."
       }
    }

=over 4

=item assigned_to

担当者（メールアドレス)

=item cc

通知先CC(カンマ区切り)

=item description

概要・説明

=item due_on

締め切り日

=item id

イッシューID

=item issue_type

イッシュー種別

=item milestone_id

マイルストーンID

=item project_id

プロジェクトID

=item resolution

状態 (デフォルト 'open')

=item severity

イッシュー重要度

=item target

修正対象コンポーネント

=item title

タイトル

=item version

修正対象バージョン

=back

=head2 issue.search

既存のイッシューを検索します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "option" : "...",
          "where" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item option (Str, optional)

ソート順などの指定

=item where (Str, optional)

検索条件

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 issue.set_subissues

既存のイッシューにサブイッシューを紐付けます

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "issue_id" : "...",
          "subissues" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

操作者メールアドレス

=item issue_id (Int, required)

親となるイッシューID

=item subissues (ArrayRef[Int], required)

サブイッシューIDのリスト

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 issue.comments

任意のイッシューに紐付いたコメント一覧を取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "issue_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item issue_id (Int, required)

対象イッシューID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "comments" : "..."
       }
    }

=over 4

=item comments

コメントのリスト（ハッシュの内容はissue.comment.fetchの戻り値を参照）

=back

=head2 issue.comment.create

新規コメントを作成します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "body" : "...",
          "issue_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

投稿者メールアドレス

=item body (Str, required)

コメント本文

=item issue_id (Int, required)

コメント対象イッシューID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

作成したコメントID

=back

=head2 issue.comment.fetch

既存コメントを取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)



=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "body" : "...",
          "created_on" : "...",
          "id" : "...",
          "modified_on" : "..."
       }
    }

=over 4

=item body

コメント本文

=item created_on

登録日時

=item id

コメントID

=item modified_on

情報更新日時

=back

=head2 issue.attachments

任意のイッシューに紐付いている添付ファイル情報の取得

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "issue_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item issue_id (Int, required)

対象イッシューID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "attachments" : "..."
       }
    }

=over 4

=item attachments

添付ファイル情報のリスト（ハッシュの内容はissue.attachment.fetchの戻り値を参照）

=back

=head2 issue.attachment.create

新規ファイル添付

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "body" : "...",
          "filename" : "...",
          "issue_id" : "...",
          "mimetype" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

投稿者メールアドレス

=item body (Str(Base64), required)

ファイルデータ

=item filename (Str, required)

添付ファイル名

=item issue_id (Int, required)

添付対象イッシューID

=item mimetype (Str, required)

添付ファイルのMIME種別

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "id" : "..."
       }
    }

=over 4

=item id

作成された添付ファイルID

=back

=head2 issue.attachment.fetch

既存添付ファイル情報取得

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)

添付ファイルID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "filename" : "...",
          "issue_id" : "...",
          "mimetype" : "...",
          "url" : "..."
       }
    }

=over 4

=item filename

添付ファイル名

=item issue_id

添付対象イッシューID

=item mimetype

添付ファイルのMIME種別

=item url

ファイル本体取得用URL

=back

=head2 issue.attachment.delete

既存添付ファイル削除

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

削除者メールアドレス

=item id (Int, required)

添付ファイルID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 issue.actions

対象イッシューに紐尽くアクションのリストを取得

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "issue_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item issue_id (Int, required)

対象イッシューID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "actions" : "..."
       }
    }

=over 4

=item actions

アクションのリスト（ハッシュの内容はissue.action.fetchの戻り値を参照）

=back

=head2 issue.action.fetch

イッシューに紐尽くアクションの取得

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item id (Int, required)

アクションID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "action" : "...",
          "issue_id" : "...",
          "message" : "..."
       }
    }

=over 4

=item action

アクション種別

=item issue_id

対象イッシューID

=item message

メッセージ

=back

=head2 issue.summarybyproject.fetch

プロジェクトに紐付けられたイッシュー統計情報を取得します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "project_id" : "..."
       }
    }

=over 4

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item project_id (Str, required)

プロジェクトID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {
          "project_id" : "...",
          "total_critical" : "...",
          "total_major" : "...",
          "total_minor" : "...",
          "total_nitpick" : "...",
          "total_open" : "...",
          "total_wishlist" : "..."
       }
    }

=over 4

=item project_id

プロジェクトID

=item total_critical

criticalのイッシュー数

=item total_major

majorのイッシュー数

=item total_minor

minorのイッシュー数

=item total_nitpick

nitpickのイッシュー数

=item total_open

openのイッシュー数

=item total_wishlist

wishlistのイッシュー数

=back

=head2 project.member.add

プロジェクトに、プロジェクトメンバーを追加します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "account_id" : "...",
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "project_id" : "..."
       }
    }

=over 4

=item account_id (Str, required)

プロジェクトメンバーとして登録する人のメールアドレス

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

操作者メールアドレス

=item project_id (Str, required)

プロジェクトID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back

=head2 project.member.delete

プロジェクトから、プロジェクトメンバーを削除します

=head3 request 

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "params" : {
          "account_id" : "...",
          "auth.api_key" : "...",
          "auth.api_secret" : "...",
          "author" : "...",
          "project_id" : "..."
       }
    }

=over 4

=item account_id (Str, required)

プロジェクトメンバーから削除する人のメールアドレス

=item auth.api_key (Str, required)

Cirqueから発行されたアプリケーション認証用API-Key

=item auth.api_secret (Str, required)

Cirqueから発行されたアプリケーション認証用API-Secret

=item author (Str, required)

操作者メールアドレス

=item project_id (Str, required)

プロジェクトID

=back

=head3 response

    {
       "id" : "...",
       "jsonrpc" : "2.0",
       "result" : {}
    }

=over 4

=back


