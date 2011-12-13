[
    {
        name => "project.projects",
        description => "プロジェクト一覧を取得します。",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
        },
        result => {
            projects => { isa => 'ArrayRef[HashRef]', description => "プロジェクトのリスト",  },
        }
    },
    {
        name => "project.create",
        description => "プロジェクトを新規作成します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            name              => { required => 1, isa => 'Str', description => "プロジェクト名" },
            author            => { required => 1, isa => 'Str', description => "作成者メールアドレス" },
            slug              => { required => 1, isa => 'Str', description => "省略名 (URLに使用)" },
            description       => { required => 1, isa => 'Str', description => "プロジェクト詳細" },
        },
        result => {
            id => { isa => 'Str', description => "作成されたプロジェクトID" },
        }
    },
    {
        name => "project.update",
        description => "既存プロジェクトを変更します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Str', description => "プロジェクトID" },
            author            => { required => 1, isa => 'Str', description => "変更者メールアドレス" },
            name              => { required => 0, isa => 'Str', description => "プロジェクト名" },
            slug              => { required => 0, isa => 'Str', description => "省略名 (URLに使用)" },
            description       => { required => 0, isa => 'Str', description => "プロジェクト詳細" },
        },
        result => {
            id => { isa => 'Str', description => "変更されたプロジェクトID" },
        }
    },
    {
        name => "project.fetch",
        description => "既存プロジェクト情報を取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 0, description => "プロジェクトID (slugが無い場合は必須)" },
            slug              => { required => 0, description => "プロジェクト省略名 (idが無い場合は必須)" },
        },
        result => {
            id           => { isa => 'Str', description => "プロジェクトID" },
            name         => { isa => 'Str', description => "プロジェクト名" },
            slug         => { isa => 'Str', description => "省略名" },
            description  => { isa => 'Str', description => "説明文" },
            created_on   => { isa => 'Datetime', description => "登録日時" },
            modified_on  => { isa => 'Datetime', description => "情報更新日時" },
            repositories => { isa => "[Array[Int]]", description => "レポジトリIDの配列" },
            members      => { isa => "[Array[Str]]", description => "プロジェクトメンバーのリスト" },
        }
    },
    {
        name => "project.milestones",
        description => "既存プロジェクトに登録されているマイルストーンリストを取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => 'Str', description => "プロジェクトID" },
        },
        result => {
            milestones => { isa => 'ArrayRef[HashRef]', description => "マイルストーンのリスト" },
        }
    },
    {
        name => "project.repositories",
        description => "既存プロジェクトに登録されているレポジトリリストを取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => 'Str', description => "プロジェクトID" },
        },
        result => {
            repositories => { isa => 'ArrayRef[HashRef]', description => "レポジトリのリスト" },
        }
    },
    {
        name => "repository.branches",
        description => "既存レポジトリに登録されているブランチリストを取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => "Str", description => "レポジトリID" },
        },
        result => {
            branches => { isa => 'ArrayRef[HashRef]', description => "ブランチのリスト" },
        }
    },
    {
        name => "repository.sync",
        description => "既存レポジトリの同期を行います",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { requierd => 1, isa => 'Str', description => "レポジトリID" },
        },
        result => {}
    },
    {
        name => "repository.create",
        description => "既存プロジェクトに新規レポジトリを追加します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => 'Str', description => "プロジェクトID" },
            name              => { required => 1, isa => 'Str', description => "レポジトリ名" },
            url               => { required => 1, isa => 'Str', description => "レポジトリURL" },
        },
        result => {
            id => { isa => 'Int', description => "新規レポジトリID" },
        },
    },
    {
        name => "repository.fetch",
        description => "既存レポジトリの情報を取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Str', description => "レポジトリID" },
        },
        result => {
            id          => { isa => "Str", description => "レポジトリID" },
            project_id  => { isa => "Str", description => "プロジェクトID" },
            name        => { isa => "Str", description => "レポジトリ名" },
            url         => { isa => "Str", description => "レポジトリURL" },
            created_on  => { isa => "Datetime", description => "登録日時" },
            modified_on => { isa => "Datetime", description => "情報更新日時" },
        }
    },
    {
        name => "repository.update",
        description => "既存レポジトリの情報を変更します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "レポジトリID" },
            name              => { required => 0, isa => 'Str', description => "レポジトリ名" },
            url               => { required => 0, isa => 'Str', description => "レポジトリURL" },
        },
        result => {
            id => { isa => 'Int', description => "変更対象のレポジトリID" },
        },
    },
    {
        name => "repository.delete",
        description => "既存レポジトリを削除します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "レポジトリID" },
        },
        result => {},
    },
    {
        name => "issue.create",
        description => "新規イッシューを作成します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => 'Str', description => "プロジェクトID" },
            author            => { required => 1, isa => 'Str', description => "作成者メールアドレス" },
            milestone_id      => { required => 0, isa => 'Int', description => "マイルストーンID" },
            title             => { required => 1, isa => 'Str', description => "タイトル" },
            issue_type        => { required => 1, isa => "ENUM(bug,feature,improvement,wishlist)", description => "イッシュー種別" },
            severity          => { required => 1, isa => "ENUM(critical,major,minor,nitpick,wishlist)", description => "イッシュー重要度" },
            description       => { required => 1, isa => 'Str', description => "概要・説明" },
            resolution        => { required => 0, isa => "ENUM(open,in-progress,fixed,wontfix,dup,closed)", description => "状態 (デフォルト 'open')" },
            target            => { required => 0, isa => 'Str', description => "修正対象コンポーネント" },
            assigned_to       => { required => 0, isa => 'Str', description => "担当者（メールアドレス)" },
            version           => { required => 0, isa => 'Str', description => "修正対象バージョン" },
            due_on            => { required => 0, isa => 'Datetime', description => "締め切り日" },
            cc                => { required => 0, isa => 'Str', description => "通知先CC(カンマ区切りで複数入力)" },
            parent_issue_id   => { required => 0, isa => 'Int', description => "親イッシューID" },
        },
        result => {
            id => { isa => 'Int', description => "作成されたイッシューID" },
        }
    },
    {
        name => "issue.update",
        description => "既存イッシューを変更します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "変更したいイッシューのID" },
            author            => { required => 1, isa => 'Str', description => "変更者メールアドレス" },
            project_id        => { required => 0, isa => 'Str', description => "プロジェクトID" },
            milestone_id      => { required => 0, isa => 'Int', description => "マイルストーンID" },
            title             => { required => 0, isa => 'Str', description => "タイトル" },
            issue_type        => { required => 0, isa => "ENUM(bug,feature,improvement,wishlist)", description => "イッシュー種別" },
            severity          => { required => 0, isa => "ENUM(critical,major,minor,nitpick,wishlist)", description => "イッシュー重要度" },
            description       => { required => 0, isa => 'Str', description => "概要・説明" },
            resolution        => { required => 0, isa => "ENUM(open,in-progress,fixed,wontfix,dup,closed)", description => "状態 (デフォルト 'open')"  },
            target            => { required => 0, isa => 'Str', description => "修正対象コンポーネント" },
            assigned_to       => { required => 0, isa => 'Str', description => "担当者（メールアドレス)", },
            version           => { required => 0, isa => 'Str', description => "修正対象バージョン" },
            due_on            => { required => 0, isa => 'Datetime', description => "締め切り日" },
            cc                => { required => 0, isa => 'Str', description => "通知先CC(カンマ区切りで複数入力)" },
            parent_issue_id   => { required => 0, isa => 'Int', description => "親イッシューID"  },
        },
        result => {
            id => { isa => 'Int', description => "変更されたイッシューID" },
        }
    },
    {
        name => "issue.fetch",
        description => "既存イッシューを取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "取得したいイッシューのID" },
        },
        result => {
            id           => { isa => 'Int', description => "イッシューID" },
            project_id   => { isa => 'Str', description => "プロジェクトID" },
            milestone_id => { isa => 'Int', description => "マイルストーンID" },
            title        => { isa => 'Str', description => "タイトル" },
            issue_type   => { isa => "ENUM(bug,feature,improvement,wishlist)", description => "イッシュー種別" },
            severity     => { isa => "ENUM(critical,major,minor,nitpick,wishlist)", description => "イッシュー重要度" },
            description  => { isa => 'Str', description => "概要・説明" },
            resolution   => { isa => "ENUM(open,in-progress,fixed,wontfix,dup,closed)", description => "状態 (デフォルト 'open')" },
            target       => { isa => 'Str', description => "修正対象コンポーネント" },
            assigned_to  => { isa => 'Str', description => "担当者（メールアドレス)" },
            version      => { isa => 'Str', description => "修正対象バージョン" },
            due_on       => { isa => 'Datetime', description => "締め切り日" },
            cc           => { isa => 'Str', description => "通知先CC(カンマ区切り)" },
            # 親イッシューのIDを取る？
        },
    },
    {
        name => "issue.search",
        description => "既存のイッシューを検索します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            where             => { required => 0, description => "検索条件" },
            option            => { required => 0, description => "ソート順などの指定" },
        },
        result => {},
    },
    {
        name => "issue.set_subissues",
        description => "既存のイッシューにサブイッシューを紐付けます",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            author            => { required => 1, isa => "Str", description => "操作者メールアドレス" },
            issue_id          => { required => 1, isa => "Int", description => "親となるイッシューID" },
            subissues         => { required => 1, isa => "ArrayRef[Int]", description => "サブイッシューIDのリスト" },
        },
        result => {},
    },
    {
        name => "issue.comments",
        description => "任意のイッシューに紐付いたコメント一覧を取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            issue_id          => { required => 1, isa => 'Int', description => "対象イッシューID" },
        },
        result => {
            comments => { isa => "ArrayRef[HashRef]", description => "コメントのリスト（ハッシュの内容はissue.comment.fetchの戻り値を参照）" },
        }
    },
    {
        name => "issue.comment.create",
        description => "新規コメントを作成します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            issue_id          => { required => 1, isa => 'Int', description => "コメント対象イッシューID" },
            author            => { required => 1, isa => 'Str', description => "投稿者メールアドレス" },
            body              => { required => 1, isa => 'Str', description => "コメント本文" },
        },
        result => {
            id => { isa => 'Int', description => "作成したコメントID" }
        },
    },
    {
        name => "issue.comment.fetch",
        description => "既存コメントを取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', decription => "取得するコメントID" },
        },
        result => {
            id          => { isa => 'Int', description => "コメントID" },
            body        => { isa => 'Str', description => "コメント本文" },
            created_on  => { isa => 'Datetime', description => "登録日時" },
            modified_on => { isa => 'Datetime', description => "情報更新日時" },
        }
    },
    {
        name => "issue.attachments",
        description => "任意のイッシューに紐付いている添付ファイル情報の取得",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            issue_id          => { required => 1, isa => 'Int', description => "対象イッシューID" },
        },
        result => {
            attachments => { isa => "ArrayRef[HashRef]", description => "添付ファイル情報のリスト（ハッシュの内容はissue.attachment.fetchの戻り値を参照）" },
        }
    },
    {
        name => "issue.attachment.create",
        description => "新規ファイル添付",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            issue_id          => { required => 1, isa => 'Int', description => "添付対象イッシューID" },
            author            => { required => 1, isa => 'Str', description => "投稿者メールアドレス" },
            filename          => { required => 1, isa => 'Str', description => "添付ファイル名" },
            mimetype          => { required => 1, isa => 'Str', description => "添付ファイルのMIME種別" },
            body              => { required => 1, isa => "Str(Base64)", description => "ファイルデータ" },
        },
        result => {
            id => { isa => 'Int', description => "作成された添付ファイルID" },
        },
    },
    {
        name => "issue.attachment.fetch",
        description => "既存添付ファイル情報取得",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "添付ファイルID" },
        },
        result => {
            issue_id => { isa => 'Int', description => "添付対象イッシューID" },
            filename => { isa => 'Str', description => "添付ファイル名" },
            mimetype => { isa => 'Str', description => "添付ファイルのMIME種別" },
            url      => { isa => 'Str', description => "ファイル本体取得用URL" },
        },
    },
    {
        name => "issue.attachment.delete",
        description => "既存添付ファイル削除",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "添付ファイルID" },
            author            => { required => 1, isa => 'Str', description => "削除者メールアドレス" },
        },
        result => {},
    },
    {
        name => "issue.actions",
        description => "対象イッシューに紐尽くアクションのリストを取得",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            issue_id          => { required => 1, isa => 'Int', description => "対象イッシューID" },
        },
        result => {
            actions => { isa => 'ArrayRef[HashRef]', description => "アクションのリスト（ハッシュの内容はissue.action.fetchの戻り値を参照）" },
        }
    },
    {
        name => "issue.action.fetch",
        description => "イッシューに紐尽くアクションの取得",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => 'Int', description => "アクションID" },
        },
        result => {
            issue_id => { isa => 'Int', description => "対象イッシューID" },
            action   => { isa => 'Str', description => "アクション種別" },
            message  => { isa => 'Str', description => "メッセージ" },
        }
    },
    {
        name => "issue.summarybyproject.fetch",
        description => "プロジェクトに紐付けられたイッシュー統計情報を取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => 'Str', description => 'プロジェクトID' },
        },
        result => {
            project_id     => { isa => 'Str', description => 'プロジェクトID' },
            total_open     => { isa => 'Int', description => 'openのイッシュー数' },
            total_critical => { isa => 'Int', description => 'criticalのイッシュー数' },
            total_major    => { isa => 'Int', description => 'majorのイッシュー数' },
            total_minor    => { isa => 'Int', description => 'minorのイッシュー数' },
            total_nitpick  => { isa => 'Int', description => 'nitpickのイッシュー数' },
            total_wishlist => { isa => 'Int', description => 'wishlistのイッシュー数' },
        }
    },
    {
        name => "project.member.add",
        description => "プロジェクトに、プロジェクトメンバーを追加します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => "Str", description => "プロジェクトID" },
            account_id        => { required => 1, isa => "Str", description => "プロジェクトメンバーとして登録する人のメールアドレス" },
            author            => { required => 1, isa => "Str", description => "操作者メールアドレス" },
        },
        result => {},
    },
    {
        name => "project.member.delete",
        description => "プロジェクトから、プロジェクトメンバーを削除します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => "Str", description => "プロジェクトID" },
            account_id        => { required => 1, isa => "Str", description => "プロジェクトメンバーから削除する人のメールアドレス" },
            author            => { required => 1, isa => "Str", description => "操作者メールアドレス" },
        },
        result => {},
    },
    {
        name => "project.irc.create",
        description => "プロジェクトに、IRC接続先情報を追加します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            project_id        => { required => 1, isa => "Str", description => "プロジェクトID" },
            host              => { required => 1, isa => "Str", description => "IRC接続先ホストおよびポート番号" },
            account           => { required => 0, isa => "Str", description => "IRC接続用アカウント" },
            password          => { required => 1, isa => "Str", description => "IRC接続用パスワード" },
            channels          => { required => 1, isa => "Array[Str]", description => "接続先チャンネルリスト" },
            author            => { required => 1, isa => "Str", description => "操作者メールアドレス" },
        },
        result => {
            id => { isa => 'Int', description => "IRC情報ID" },
        },
    },
    {
        name => "project.irc.update",
        description => "プロジェクトに登録されているIRC接続先情報を編集します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => "Str", description => "IRC情報ID" },
            project_id        => { required => 0, isa => "Str", description => "プロジェクトID" },
            host              => { required => 0, isa => "Str", description => "IRC接続先ホストおよびポート番号" },
            account           => { required => 0, isa => "Str", description => "IRC接続用アカウント" },
            password          => { required => 0, isa => "Str", description => "IRC接続用パスワード" },
            channels          => { required => 0, isa => "Array[Str]", description => "接続先チャンネルリスト" },
            author            => { required => 1, isa => "Str", description => "操作者メールアドレス" },
        },
        result => {
            id => { isa => 'Int', description => "IRC情報ID" },
        },
    },
    {
        name => "project.irc.delete",
        description => "プロジェクトに登録されているIRC接続先情報を削除します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => "Str", description => "IRC情報ID(プロジェクトIDが指定されている場合は不要)" },
            project_id        => { required => 1, isa => "Str", description => "プロジェクトID(IRC情報IDが指定されている場合は不要)" },
        },
        result => {},
    },
    {
        name => "project.irc.fetch",
        description => "プロジェクトに登録されているIRC接続先情報を取得します",
        params => {
            'auth.api_key'    => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Key" },
            'auth.api_secret' => { required => 1, isa => "Str", description => "Cirqueから発行されたアプリケーション認証用API-Secret" },
            id                => { required => 1, isa => "Str", description => "IRC情報ID(プロジェクトIDが指定されている場合は不要)" },
            project_id        => { required => 1, isa => "Str", description => "プロジェクトID(IRC情報IDが指定されている場合は不要)" },
        },
        result => {
            rows => { isa => 'Array', description => "IRC情報のリスト" },
        },
    },
];
