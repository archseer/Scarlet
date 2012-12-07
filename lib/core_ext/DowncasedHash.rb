class DowncasedHash < Hash

  def convert_key obj
    obj.respond_to?(:downcase) ? obj.downcase : obj
  end

  private :convert_key

  def [] key 
    super convert_key(key)
  end

  def []= key, value 
    super convert_key(key), value 
  end

  def delete key 
    super convert_key(key)
  end

  def include? key 
    super convert_key(key)
  end

  def has_key? key
    super convert_key(key)
  end

end