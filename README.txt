プログラム説明

＜必要な準備＞
１．Rubyの最新版のインストール
２．必要なライブラリのインストール
　　コマンドプロンプトにて，ディレクトリはどこでもいいので以下のコマンドを打ち込む
　　Rubyが正しくインストールできていれば，ライブラリのインストールが始まる
　　・gem install oauth
　　・gem install json
　　・gem install uri			（もしかしたらいらないかも）
３．Twitterアカウントからの，developer登録と認証キーの取得が必要
　　参照：https://syncer.jp/twitter-api-matome
　　・CONSUMER_KEY, CONSUMER_SECRET
　　・ACCESS_TOKEN, ACCESS_TOKE_SECRET
　　の四つの取得が必要
４．取得した情報をもとに，"author_sample.json"ファイルを書き換える
５．書き換えた"author_sample.json"ファイルのファイル名を"author.json"に変更する

＜実行方法＞
実行コマンド ruby -Ku get-conversation-from-twitter.rb ＜クエリ＞

実行時の引数に単語を指定すると，その単語についての会話を取得する
＜クエリ＞　を　単語　に変えて実行する
もし引数を指定しないと，デフォルトでは料理についての会話を取得するよう設定している

＜プログラム内容＞
・引数に指定した単語を含む最新100件のtweetを取得し，その中からリプライであるもののみを抽出する

・リプライ元のツイートを取得し，会話のセットであるとしてファイルに保存する

・ファイルの保存形式は以下の形式である

-----data00000.txt------------
<user_id1>:<tweet_text1>
<tweet_text1>
<tweet_text1>				// <- ここまで<user_id1>の発話
<user_id2>:<tweet_text2>
----------------------------------

・property.json ファイルで，検索結果から照合・除外するツイートのルールを制御している
　　・同じツイートを検索しないようにする場合は"excluding repeated tweet_id"をtrueにする
　　・（同じツイートでなくても）同じ文章のツイートを検索しないようにする場合は"excluding repeated text"をtrueにする
　　・特定のユーザからのツイートを検索結果から除外する場合は"blacklist"をtrueにし，"./database/blacklist.txt"に除外したいユーザIDを追加する．

・ログファイル(tweet_list.json)によって，ファイルに保存したツイートのIDおよびテキスト内容を記憶する

・たまにコンソール上に{errors...}と，APIエラーが吐き出されるようになっているが，これは鍵アカウントにアクセスしようとしているためである
　この場合はエスケープ処理を行い，ファイル保存されないようになっている

・API切れ対策のため，一ループが終わるごとに15分スリープしている

＜改善すべき点＞　
・API切れのタイミングでのみスリープするようにする

・ツイートの検索範囲（日時やツイートID）を制御できるようにする
