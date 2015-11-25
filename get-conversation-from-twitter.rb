# Search.rb

require 'oauth'
require 'json'
require 'uri'

require './my-twitter.rb'
require './tweet.rb'
require './text.rb'

#########################
##         準備         ##
#########################

# Twitterアクセスのための準備
twitter = Twitter.authorized_from_json("./author.json")
twitter.ready_to_access unless twitter.ready_to_access?

# ディレクトリの準備
directory_name = "./database"
Dir.mkdir(directory_name) unless Dir.exist?(directory_name)

# ツイートの検索結果の重複を避けるためのログファイルの読み込み
list_json_name = "#{directory_name}/tweet_id_list.json"

# jsonファイルが存在しない場合は新規作成する
Text.new(["{", "\"sample_tweet_id\":\"sample_file_name\"", "}"]).write(list_json_name) unless File.exist?(list_json_name)

# jsonファイルから読み込む
list_json = File.open(list_json_name) do |io|
  JSON.load(io)
  # <tweet_id> => <file_name>
end

# コマンドからの引数を検索クエリとする
query = (ARGV[0]==nil)?("料理"):ARGV[0] # コマンドからの引数がない場合は"料理"を検索

# 保存したファイル数をカウントする変数
# コンソール出力に利用するだけなのでなくてもよい
count = 0

###########################
#      ここから検索ループ      #
###########################

loop do

  ############################
  ##  未発見の会話の探索start  ##
  ############################

  # Twitter からqueryを含むツイートを検索し，結果の取得
  result = twitter.search("#{query}")
  # => json as {"search"=>[<search results>], "search_metadata"=>{}}

  # 検索結果からリプライである新規発見ツイートのみ抽出する
  @tweets = Array.new()
  result["statuses"].size.times do |i|
    tweet = Tweet.init(result["statuses"][i])

    # replyでない場合は除外
    next unless tweet.reply?

    # もしすでにデータベースに保存されている（list_jsonに記憶してある）場合は除外
    next if list_json.has_key?(tweet.tweet_id)    

    # 新しく発見された会話のツイートをスタックに格納
    @tweets.push(tweet) 
  end

  ##########################
  ##  未発見の会話の探索end  ##
  ##########################

  ##################################
  ##       会話の抽出処理start      ##
  ##################################

  # １会話ごとにファイル出力するためのループ
  @tweets.size.times do |i|
    # ファイル名の準備
    file_name = sprintf("#{directory_name}/data%05d.txt", Dir.glob("#{directory_name}/*.txt").count)

    # 会話の配列の取得
    conversation = twitter.get_conversation(@tweets[i].tweet_id)

    # 発話数が2未満で会話になっていない場合は除外する
    next if conversation.size < 2

    # 出力に用いるテキストクラスの準備
    output = Text.new()

    # 発言を一つずつテキストクラスに格納
    conversation.size.times do |j|
      output.push(conversation[j].format)
    end

    # テキストのファイル出力
    output.write(file_name)

    # ログファイルの更新
    list_json[@tweets[i].tweet_id] = file_name
    File.open(list_json_name, "w") do |io|
      JSON.dump(list_json, io)
    end

    # コンソールへの出力
    puts "----------------------------------------"
    puts "save an conversation below as \"#{file_name}\""
    puts "----------------------------------------"
    puts output

    # カウンタのインクリメント
    count += 1
  end

  ##################################
  ##        会話の抽出処理end       ##
  ##################################


  ##################
  ## 処理結果の表示 ##
  ##################

  puts "------------------------------------------------------"
  puts "searched the newest 100 tweets including \"#{query}\""
  puts "#{count} conversations were saved in \"#{directory_name}\"．"
  puts "------------------------------------------------------"

  # 一回のループあたりで，
  # /search/ API 消費 1
  # /statuses/ API 消費 (count * 会話数)
  #puts "------------------------------------------------------"
  #puts "#{twitter.rate_limit("statuses")}" # 残APIの表示
  #puts "------------------------------------------------------"

  #######################
  # API回復のためsleep処理 #
  #######################

  # sleep時間の設定
  minutes = 15

  puts "----------------------------------------"
  puts "sleeping #{minutes} minutes to wait for API limit. ('.' means one minute passed)"
  puts "(please input {<Ctrl> + 'C'}) to interrupt the next loop"

  minutes.times do |i|
    puts "."
    sleep(60) # => 5 minutes
  end

  puts "----------------------------------------"

  #######################
  #       sleep終了      #
  #######################

end