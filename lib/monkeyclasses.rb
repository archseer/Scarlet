class HashTConvert < Hash

  def try_convert obj
    obj
  end

  private :try_convert

  def [] key 
    super try_convert(key)
  end

  def []= key, value 
    super try_convert(key), value 
  end

  def delete key 
    super try_convert(key)
  end

  def include? key 
    super try_convert(key)
  end

  def has_key? key
    super try_convert(key)
  end
  
end

class HashDowncased < HashTConvert

  def try_convert obj
    obj.respond_to?(:downcase) ? obj.downcase : obj
  end

end