# property.rb
require 'json'

class Property < Hash

  def self.init_from_json(file_name)
    hash = File.open(file_name) do |io|
      JSON.load(io)
    end
    return self.new(hash)
  end

  def initialize(hash)
    hash.each do |key, val|
      self[key] = val
    end
  end

  def on?(key)
    return (self[key] == "on" || self[key] == true)?true:false 
  end
end
