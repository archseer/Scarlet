require 'set'

class Object
  def nil_zero?
    self.nil? || self == 0
  end
  def to_bool
    !!self
  end
end

class Array
  def subtract_once *values
    values = Set.new values
    self.replace reject { |e| values.include?(e) && values.delete(e) }
  end
end

class Time
  def std_format
    self.strftime("%c")
  end
end

class String
  def word_wrap line_width = 65
    text = self
    return text if line_width <= 0
    text.gsub(/\n/, ' ').gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip.split("\n")
  end
  def character_wrap characters=490
    text = self
    return text if characters <= 0
    result,r = [],""
    text.split(' ').each do |word|
      (result << r;r = "") unless r.size + word.size <= characters
      r += word
    end
    result << r unless r.empty?
    result
  end
  def align width = 70, orientation = :left, padding=2
    text = self
    text.strip!
    l = text.length
    if l < width
      margin = width-(l+padding*2) > 0 ? width-(l+padding*2) : 0
      if orientation == :right
        text = (" " * padding) + (" " * margin) + text + (" " * padding)
      elsif orientation == :left
        text = (" " * padding) + text  + (" " * margin) + (" " * padding)
      elsif orientation == :center
        left_margin = (width - l)/2
        right_margin = width - l - left_margin
        text = (" " * left_margin) + text + (" " * right_margin)
      end
    end
    text
  end

  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
  def str2bool bool=false
    case self.upcase
    when "TOGGLE", "SWITCH" ; !bool
    when "ON", "TRUE"       ; true
    when "OFF", "FALSE"     ; false
    else                    ; bool
    end
  end
end

class Hash
  def symbolize_values
    inject Hash.new do |hsh, (key, value)| hsh[key] = value.to_s.to_sym ; hsh ; end
  end
  def symbolize_values!
    self.replace symbolize_values
  end
  def get_values *args
    args.collect{|sym|self[sym]}
  end

  def replace_key *args,&block
    dup.replace_key! *args,&block
  end
  def replace_key! hash={}
    k,v = [nil]*2
    if block_given?
      keyz = self.keys
      keyz.each do |k| v = yield k ; self[v] = self.delete k end
    else
      hash.each_pair do |k,v| self[v] = self.delete k end
    end
    self
  end
  def remap &block
    dup.remap! &block
  end
  def remap!
    key,value = [nil]*2
    hsh = self.each_pair.to_a; self.clear
    hsh.each do |(key,value)|
      key,value = yield key,value; self[key] = value
    end
    self
  end
end

class File
  def tail n
    buffer = 1024
    idx = (size - buffer).abs
    chunks = []
    lines = 0

    begin
      seek(idx)
      chunk = read(buffer)
      lines += chunk.count("\n")
      chunks.unshift chunk
      idx -= buffer
    end while lines < n && pos != 0

    chunks.join.lines.reverse_each.take(n).reverse.join
  end
end