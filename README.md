# NS用　オートセーブスクリプト（nettool必須）

## このスクリプトについて
- 当NSで使用しているNetSimutransで一定時間セーブがないときに自動でセーブを書くスクリプトです

## 注意
- このスクリプトは単体では動きません
    - nettool(公式がソース公開　ビルド必須)
        - 別途用意してください
    - version
    - version_server
        - KU-TANS標準起動スクリプトに含まれています
            - 詳しくは下記のリンク先からご確認ください
- デフォルトではKU-TANS標準起動スクリプトの使用が前提になっています(変更可)
    - Simutrans_StartupScript(自家製：https://github.com/KU-TANS/Simutrans_StartupScript)
        - pak.pakname_server.ps1
        - pak.pakname_server.exe ( Windows用実行ファイル )
- PowerShellが実行できる環境が必要です
    - 実行環境がない場合は以下を参考にインストールしてください
        - Linux への PowerShell のインストール
            - https://docs.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1
        - PowerShellリリースページ
            - https://github.com/PowerShell/PowerShell/releases
    - `Security warning`が表示されるときはExecutionPolicyを変更してください
- エラー処理は実装していません

## 導入方法
1. 必要となるファイルをSimutrans本体と同じディレクトリに配置する
    - 必須
        - autosave_windows.ps1もしくはautosave_linux.ps1
        - version
        - version_server
        - saveファイル
            - 例：13353ポートを使用している場合
                - server13353-network.sve
    - 推奨
        - KU-TANS標準起動スクリプト
            - https://github.com/KU-TANS/Simutrans_StartupScript
1. autosave_windows.ps1もしくはautosave_linux.ps1をリネームする
    - 詳しくは[スクリプト一覧](#スクリプト一覧)をご覧ください
1. スクリプト内に設定を書き込む
    - 詳しくは[各種設定について](#各種設定について)をご確認ください

## 仕様
- versionファイルやversion_serverファイルの情報を元に動きます
- NSで一定時間ごとにセーブを行います
- Simutransが落ちている場合に再起動します
- pakの名前が違う場合にはスクリプト名を書き換えてください
    - autosave_〇〇.ps1のような形式で書き換えます
    - 例：autosave_pak.nippon.ps1
- オートセーブのタイミングにSimutransが起動していなければ再起動します
    - スクリプト起動時にSimutransが起動していなければ起動します
- セーブ間隔は最後に書かれたセーブが元になります
    - 例：30分間隔の時、オートセーブの20分後にセーブが書かれたとする
        - オートセーブのタイミングではセーブを書かれない
        - 最新のセーブデータをバックアップする
        - そのセーブデータから30分後、（この状況ではバックアップから20分後）にオートセーブが行われる
- オートセーブまたは状態チェックのタイミングでプレイヤーが不在の時
    - 1つ前のオートセーブもしくはバックアップまでプレイヤーいた場合
        - セーブをした後にSimutransを再起動します
            - Simutransが長時間起動で重くなるのを防ぐため
    - それ以外の場合
        - セーブしません
### 各種設定について(10行～14行)
- 10行～14行目にあります
- 各自環境に併せて設定してください
#### セーブデータバックアップ方法(`$mode`)
- バックアップ保管方法は2種類あります
    - セーブデータを別フォルダに保管する(saveCopy)
        - ファイル名はデフォルトの名前+セーブ時間になります
        - 古いセーブデータを削除する機能はないので適宜手動で消してください
    - セーブデータをGitにpushする(push)
        - コミットメッセージがセーブ時間になります
        - git add は行わないので、初めての時は手動でセーブデータのaddを済ませておく必要があります
#### セーブデータバックアップ先(`$backup_Location`)
- セーブデータをバックアップするフォルダのパスを入力
#### Simutransを起動or再起動ファイル(`$restart_Object`)
- Simutransを起動or再起動時に実行する対象を指定してください
    - デフォルトではKU-TANS標準起動スクリプトを実行します
    - 書き換え可能です
#### オートセーブ間隔(`$span`)
- オートセーブの間隔を指定します
    - デフォルトは30分です
        - 最低間隔は3分です
#### 状態チェック間隔(`$check_State`)
- 最新セーブおよびプレイヤーの有無を確認する間隔を指定します
    - デフォルトは10分です
        - 最低間隔は1分です
            - 小数を入力することで最低間隔より短い間隔での実行は可能だと思われます（未検証）
        - オートセーブ間隔より2分以上短い必要があります

## スクリプト一覧
- autosave_windows.ps1
    - デフォルトの設定
        - バックアップ方式がgitになっています
        - saveのバックアップフォルダが入力されていません
    - autosave_windows.ps1のwindowsの部分をpakフォルダ名にリネームしたものが必要です
        - 例：autosave_pak.nippon.ps1
    - 文字コード
        - BOM付きUTF-8
    - 改行コード
        - CRLF
    - PowerShell 7.0.3 および Windows PowerShell 5.1 にて動作確認しています
        - 当NSではPowerShell 7系を使用しています
- autosave_linux.ps1
    - デフォルトの設定
        - バックアップ方式がcopyになっています
        - saveのバックアップフォルダが`./save`になっています
    - このスクリプトを終了するとSimutrans本体まで終了してしまうので注意してください
    - autosave_linux.ps1のlinuxの部分をpakフォルダ名にリネームしたものが必要です
        - 例：autosave_pak128japan.ps1
    - 文字コード
        - UTF-8 (BOM無し)
    - 改行コード
        - LF
    - PowerShell 7.1.0 にて動作確認をしています

### windows版とLinux版の違い
- 違いは以下の項目です
    - デフォルト設定
    - 文字コード
    - 改行コード
- 動作自体には差はありません
    - 文字コード、改行コードを書き換えれば別環境でも動きます
##### 各種設定のデフォルトはは弊NSの都合上です。適宜書き換えてください

## ライセンス
MITライセンス