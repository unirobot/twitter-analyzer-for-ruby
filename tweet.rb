# tweet.rb
class Tweet 
  # ハッシュからインスタンス化するファクトリメソッド
  def self.init(hash)
    if hash.has_key?("errors") then
      puts "------------------------------"
      puts hash
      puts "------------------------------"
      return Tweet.new()
    else
      return Tweet.new(
        hash["text"],
        hash["id"], 
        hash["user"]["id"],
        hash["in_reply_to_status_id"],
        hash["in_reply_to_user_id"]      
      )
    end
  end

  attr_reader :text, :tweet_id, :user_id, :reply_to_tweet_id, :reply_to_user_id

  def initialize(text = "", tweet_id = "", user_id = "", reply_to_tweet_id = "", reply_to_user_id = "")
    @text = text
    @tweet_id = tweet_id 
    @user_id = user_id
    @reply_to_tweet_id = reply_to_tweet_id
    @reply_to_user_id = reply_to_user_id
    @visible = (text == "")?false:true
  end

  # tweetが正しく取得できているか否かを返すメソッド
  def visible?
    return @visible
  end

  # リプライであるか否かを返すメソッド
  def reply?
    return (@reply_to_tweet_id == nil)?false:true 
  end
  
  # textから "@<user_name> "もしくは"@<user_name>\n" を削除した文字列を返すメソッド 
  def text_without_atmark
    output = @text
    while (output =~ /[ \n]*@\w+/) == 0 do
      output.slice!(/[ \n]*@\w+[ \n]*/)
    end
    return output
  end

  # textから "@<user_name> " を削除するメソッド   
  def text_without_atmark!
    @text = self.text_without_atmark
  end

  # <user_name>:<text>というフォーマットの文字列を返すメソッド
  def format
    return "#{@user_id}:#{self.text_without_atmark}"
  end

  # json形式のhashを返すメソッド
  def hash
    output = Hash.new()
    output["text"] = @text
    output["id"] = @tweet_id
    output["user"] = Hash.new
    output["user"]["id"] = @user_id
    output["in_reply_to_status_id"] = @reply_to_tweet_id
    output["in_reply_to_user_id"] = @reply_to_user_id
    return output
  end
end
