# text.rb
# ファイルを読み込み，各行を配列の要素として管理するクラス
# ファイル読み込みを簡略化しただけで，基本的な機能は配列と同じである

class Text < Array
  # fileからTextを一行ずつ読み込むファクトリメソッド
  # もしfile_nameが存在しない場合は新規作成する
  def self.read(file_name)
    text = Text.new
    self.new().write(file_name) unless File.exist?(file_name)
    File.open(file_name) do |file|
      while l = file.gets
        text.push(l)
      end
    end  
    return text
  end

  def initialize(array = [])
    array.size.times do |i|
      self.push(array[i].to_s)
    end
  end

  # あるクエリが含まれる行のインデックスを配列として返す
  def find_key(query)
    array = Array.new
    self.size.times do |i|
      array.push(i) if self[i].include?(query)
    end
    return array
  end
  
  # arrayで渡した数字配列にあたる行数のみを抽出したTextを返すメソッド
  def get_lines(array)
    lines = Text.new
    array.size.times do |i|
      lines.push(array[i].is_a?(Fixnum)?self[array[i]]:"method_error")
    end
    return lines
  end    

  # queryを含む行のみを抽出し，返すメソッド
  def include_key(query)
  	return self.get_lines(find_key(query))
  end

  # query を含む行があるか否かを返すメソッド
  def include_key?(query)
    return (self.find_key(query).size == 0)?false:true
  end

  # file_nameのファイルにテキストを出力するメソッド
  def write(file_name)
    File.open(file_name, "w") do |file|
      self.size.times do |i|
      	file.puts self[i]
      end
    end
  end
end