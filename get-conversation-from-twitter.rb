# get-conversation-from-twitter.rb
require 'bundler/setup'

require 'oauth'
require 'json'
require 'uri'

require './my-twitter.rb'
require './tweet.rb'
require './text.rb'
require './property.rb'

#########################
##         準備         ##
#########################
# Twitterアクセスのための準備
twitter = Twitter.authorized_from_json("./author.json")
twitter.ready_to_access unless twitter.ready_to_access?

# ディレクトリの準備
directory_name = "./database"
Dir.mkdir(directory_name) unless Dir.exist?(directory_name)

# コマンドからの引数を検索クエリとする
query = (ARGV[0]==nil)?("料理"):ARGV[0] # コマンドからの引数がない場合は"料理"を検索

#########################################################
#  検索結果から特定の処理をするためのプロパティ設定とログファイルの読み込み #
#########################################################

# propertyファイルの読み込み
property = Property.init_from_json("property.json")

# ツイートの検索結果の重複を避けるためのログファイルの読み込み
tweet_list_json_name = "#{directory_name}/tweet_list.json"
# jsonファイルが存在しない場合は新規作成する
Text.new(["{", "\"sample_tweet_id\":\"sample_tweet_text\"", "}"]).write(tweet_list_json_name) unless File.exist?(tweet_list_json_name)
# jsonファイルから読み込む
tweet_list_json = Property.init_from_json(tweet_list_json_name) # => <tweet_id> => <file_name>

# blacklist ファイルの読み込み準備
blacklist_file_name = "#{directory_name}/blacklist.txt"
# ファイル読み込み
blacklist = Text.read(blacklist_file_name)

# 検索済みでまだ会話を保存できていないツイートを保存する stack ファイルの読み込み
stack_json_name = "#{directory_name}/stack.json"
# jsonファイルが存在しない場合は新規作成する
Text.new(["{", "\"stack\":[", "]","}"]).write(stack_json_name) unless File.exist?(stack_json_name)
# jsonファイルから読み込む
stack_json = Property.init_from_json(stack_json_name)
stack = stack_json["stack"]

#######################################
#      ここから検索・会話探索の無限ループ      #
#######################################

loop do
  # property で新しいツイートの検索がtrueの場合
  if property.on?("search new tweets") then
    ############################
    ##  未発見の会話の探索start  ##
    ############################

    # 保存したファイル数をカウントする変数
    # コンソール出力に利用するだけなのでなくてもよい
    count = 0

    # Twitter からqueryを含むツイートを検索し，結果の取得
    result = twitter.search("#{query}", 10)
    # => json as {"search"=>[<search results>], "search_metadata"=>{}}

    # もしエラーが返ってきた場合は以下のループに入らないように設定
    loop_times = (result.key?("errors"))?0:result["statuses"].size

    # 検索結果からリプライである新規発見ツイートのみ抽出する
    loop_times.times do |i|
      tweet = Tweet.init(result["statuses"][i])

      # replyでない場合は除外
      next unless tweet.reply?

      # もしすでにデータベースに保存されている（list_jsonに記憶してある）場合は除外
      next if (property.on?("excluding repeated tweet_id") && tweet_list_json.key?(tweet.tweet_id))
      # 全く同じ文章の場合は除外
      next if (property.on?("excluding repeated text") && tweet_list_json.value?(tweet.text_without_atmark))
      # もしblacklistに登録されていれば除外
      next if (property.on?("blacklist") && blacklist.include?(tweet.user_id))
      # もしstackに入っていれば除外
      next if stack.include?(tweet.hash)

      # 新しく発見された会話のツイートをスタックに格納
      stack.push(tweet.hash)

      # カウンタのインクリメント
      count += 1
    end
    ##########################
    ##  未発見の会話の探索end  ##
    ##########################

    # jsonに格納
    stack_json["stack"] = stack 
    # スタックファイルの更新
    File.open(stack_json_name, "w") do |io|
      JSON.dump(stack_json, io)
    end

    puts "------------------------------------------------------"
    puts "searched the newest 100 tweets including \"#{query}\""
    puts "#{count} tweets were added to stack"
    puts "in total: #{stack.size} tweets are in stack"
    puts "------------------------------------------------------"
  end # if property["search new tweets"] then

  # property で新しいツイートの検索がtrueの場合
  if property.on?("get and save conversations") then

    ##################################
    ##       会話の抽出処理start      ##
    ##################################

    # 保存したファイル数をカウントする変数
    # コンソール出力に利用するだけなのでなくてもよい
    count = 0

    # stackから消費し終わった個数をカウントする変数
    consumed_count = 0
    # stackの読み込み
    stack_json = Property.init_from_json(stack_json_name)
    stack = stack_json["stack"]
  
    # １会話ごとにファイル出力するためのループ
    stack.size.times do |i|
      tweet = Tweet.init(stack[i])

      # ファイル名の準備
      file_name = sprintf("#{directory_name}/data%05d.txt", (Dir.glob("#{directory_name}/data*.txt").count + 1))

      # 会話の配列の取得
      conversation = twitter.get_conversation(tweet.tweet_id)

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
      tweet_list_json[tweet.tweet_id] = tweet.text_without_atmark
      File.open(tweet_list_json_name, "w") do |io|
        JSON.dump(tweet_list_json, io)
      end

      # コンソールへの出力
      puts "------------------------------------------------------"
      puts "save an conversation below as \"#{file_name}\""
      puts "------------------------------------------------------"
      puts output

      # カウンタのインクリメント
      count += 1

      # 消費した個数の記憶
      consumed_count = i + 1
    end

    puts

    # 処理が終わったところまでのツイートをスタックから排除
    stack = stack.drop(consumed_count)
    # jsonに格納
    stack_json["stack"] = stack 
    # スタックファイルの更新
    File.open(stack_json_name, "w") do |io|
      JSON.dump(stack_json, io)
    end
    ##################################
    ##        会話の抽出処理end       ##
    ##################################

    ##################
    ## 処理結果の表示 ##
    ##################

    puts "------------------------------------------------------"
    puts "#{count} conversations were saved in \"#{directory_name}\"．"
    puts "#{count} tweets were deleted from stack．"
    puts "in total: #{stack.size} tweets are in stack"
    puts "------------------------------------------------------"
  end #   if property["get and save conversations"] then

  # twitter = Twitter.change_access_token if property.on?("change access token")

  if property.on?("sleep") then
    ##################################
    ##      API残量のチェック・sleep      ##
    ##################################
    
    # APIの残量を取得
    rate_limit = twitter.rate_limit("statuses,search,application")
    
    # 処理しやすいように hash に格納
    remaining = Hash.new
    # propertyで指定し，行っている処理のみAPIの残数を取得
    remaining["search"] = rate_limit["resources"]["search"]["/search/tweets"]["remaining"] if property.on?("search new tweets")
    remaining["statuses"] = rate_limit["resources"]["statuses"]["/statuses/show/:id"]["remaining"] if property.on?("get and save conversations")
    remaining["application"] = rate_limit["resources"]["application"]["/application/rate_limit_status"]["remaining"]
    
    # 残量の表示
    remaining.each do |key, value|
      puts "#{key} API limit remaining : #{value}"
    end
    
    # 残量0のものがあればsleep
    Twitter.sleep_for_API if remaining.value?(0)
    puts "------------------------------------------------------"
  end
end # loop
