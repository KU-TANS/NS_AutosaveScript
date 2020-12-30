# NS用　オートセーブスクリプト（nettool必須）

## 注意
- このスクリプトは単体では動きません
    - nettool(公式がソース公開　ビルド必須)
        - 別途用意してください
    - version
    - version_server
        - KU-TANS標準起動スクリプトに含まれています
            - 詳しくは下記のリンク先からご確認ください
- デフォルトの状態では使えません
    - 各種設定を行う必要があります
- デフォルトではKU-TANS標準起動スクリプトの使用が前提になっています(変更可)
    - Simutrans_StartupScript(自家製：https://github.com/KU-TANS/Simutrans_StartupScript)
        - pak.pakname_server.exe(Windowsのみ)
        - pak128japan_server.ps1(Linuxのみ)
- PowerShellが実行できる環境が必要です
    - 実行環境がない場合は以下を参考にインストールしてください
        - Linux への PowerShell のインストール
            - https://docs.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1
        - PowerShellリリースページ
            - https://github.com/PowerShell/PowerShell/releases
    - `Security warning`が表示されるときはExecutionPolicyを変更してください
- 当NS用（および某NS）用に作成したものですので可能な限り一般化はしていますが、癖があります
    - ご了承ください
- 以下を参考にしながらSimutrans本体やpaksetのフォルダと同様の階層に配置してください

## 仕様
- versionファイルやversion_serverファイルの情報を元に動きます
- NSで一定時間ごとにセーブを行います
- Simutransが落ちた時に再起動します
- pakの名前が違う場合にはスクリプト名を書き換えてください
    - 例：autosave_pak.nippon.ps1
    - この形式以外の名前では動きません
- オートセーブのタイミングにSimutransが起動していなければ再起動します
    - スクリプト起動時にSimutransが起動していなければ起動します
- セーブ間隔は最後に書かれたセーブが元になります
    - 例：30分間隔の時、オートセーブの20分後にセーブが書かれたとする
        - オートセーブのタイミングではセーブを書かれない
        - 最新のセーブデータをバックアップする
        - そのセーブデータから30分後、（この状況ではバックアップから20分後）にオートセーブが行われる
- オートセーブのタイミングでプレイヤーが不在の時
    - 1つ前のオートセーブもしくはバックアップまでプレイヤーいた場合
        - セーブののちにSimutransを再起動します
            - Simutransの長時間起動で重くなるのを防ぐため
    - それ以外の場合
        - セーブしません
### 各種設定について(57行～60行)
- 57行～60行目にあります
- 各自環境に併せて設定してください
#### セーブデータバックアップ方法(`$mode`)
- バックアップ保管方法は2種類あります
    - セーブデータを別フォルダに保管する(saveCopy)
        - ファイル名はデフォルトの名前+セーブ時間になります
        - 古いセーブデータを削除する機能はないので適宜手動で消してください
    - セーブデータをGitにpushする(push)
        - コミットメッセージがセーブ時間になります
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
    - autosave_linux.ps1のpak128japanの部分をpakフォルダ名にリネームしたものが必要です
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