# my-twitter.rb
require 'oauth'
require 'json'
require 'uri'

class Twitter
  @@access_token_index = 0
  @@access_token_max = 0
  # jsonファイルから認証作業に必要な情報を読み込むメソッド
  def self.authorized_from_json(json_file_name = "./author.json")
    author = open(json_file_name) do |io|
      JSON.load(io)
    end
    access_token_max = author["access_token"].size
    return Twitter.new(author["consumer_key"], author["consumer_secret"], author["access_token"][@@access_token_index], author["access_token_secret"][@@access_token_index])
  end

  # 指定した時間だけsleepするクラスメソッド
  def self.sleep_for_API(minutes = 15, output = true)
    if output then
      puts "----------------------------------------"
      puts "sleeping #{minutes} minutes to wait for API limit. ('.' means one minute passed)"
      puts "(please input {<Ctrl> + 'C'} to interrupt this program)"
    end
    minutes.times do |i|
      puts "." if output
      sleep(60) # => 5 minutes
    end
    puts "----------------------------------------" if output
  end

  def self.change_access_token(json_file_name = "./author.json")
    @@access_token_index += 1
    @@access_token_index %= @@access_token_max
    return self.authorized_from_json(json_file_name)
  end

  # initialize method 
  def initialize(consumer_key = "", consumer_secret = "", access_token = "", access_token_secret = "")
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret
    @access_token = access_token
    @access_token_secret = access_token_secret
  end

  # Twitterへのアクセス準備ができているか否かを返すメソッド
  def ready_to_access?()
    return (@endpoint == nil)?false:true
  end

  # Twitterへのアクセスのための準備を行う
  def ready_to_access()
    consumer = OAuth::Consumer.new(
      @consumer_key,
      @consumer_secret,
      site: "https://api.twitter.com"
    )
    @endpoint = OAuth::AccessToken.new(consumer, @access_token, @access_token_secret)
  end

  # Twitterへgetリクエストを投げるメソッド
  def get(request_url)
    return @endpoint.get(request_url)
  end

  # Twitterへポストメソッドを投げるメソッド
  def put(request_url, hash)
    return @endpoint.post(request_url, hash)
  end

  # queryで指定された単語を含むツイートを検索し，
  # その検索結果のjsonのハッシュを返すメソッド
  def search(query = "料理", count = 100)
    request_url = "https://api.twitter.com/1.1/"
    request_url << "search/tweets.json?q=#{query}&count=#{count}"
    request_url = URI.escape(request_url) # URLエンコード

    response = self.get(request_url) # リクエストの送信
    return result = JSON[response.body] # レスポンスをJSON形式に変換
    # => {"search"=>[<search results>], "search_metadata"=>{}}
  end

  # tweet_idで指定したidのツイートを返すメソッド
  def show_tweet(tweet_id)
    request_url = "https://api.twitter.com/1.1/"
    request_url << "statuses/show.json?id=#{tweet_id}"
    response = self.get(request_url) # リクエストの送信
    return result = JSON[response.body] # レスポンスをJSON形式に変換
  end

  # tweet_idで指定したidのツイートを返すメソッド
  def show_user(user_id)
    request_url = "https://api.twitter.com/1.1/"
    request_url << "users/show.json?user_id=#{user_id}"
    response = self.get(request_url) # リクエストの送信
    return result = JSON[response.body] # レスポンスをJSON形式に変換
  end   

  # resourcesで指定したAPIの残リミットを返すメソッド
  def rate_limit(resources = "statuses")
    request_url = "https://api.twitter.com/1.1/"
    request_url << "application/rate_limit_status.json"
    request_url << "?resources=#{resources}" unless resources == ""
    response = self.get(request_url) # リクエストの送信
    return JSON[response.body] # レスポンスをJSON形式に変換
  end

  # tweet_id_strで指定したツイートのリプライ元をcountだけ取得し，配列として返すメソッド
  # 配列への格納は時系列順
  # tweet.rbのrequire が必要
  def get_conversation(tweet_id, count = 2)
    array = Array.new
    tweet = Tweet.init(self.show_tweet(tweet_id))
    count.times do 
      # tweetが利用可能でない場合はbreak
      break unless tweet.visible?
      # tweetが利用可能であれば配列に格納
      array.push(tweet) 
      # tweetがリプライでない場合はbreak
      break unless tweet.reply?
      # tweetがリプライであるならば，リプライ先のツイートを取得
      tweet = Tweet.init(self.show_tweet(tweet.reply_to_tweet_id))
    end
    return array.reverse
  end
end