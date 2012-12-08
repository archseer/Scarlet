class Hash
  def replace_key *args,&block
    dup.replace_key! *args, &block
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
    Hash[*self.map(&block).flatten]
  end

  def remap! &block
    self.replace remap(&block)
  end
end