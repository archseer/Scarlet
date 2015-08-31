module Process
  def self.harakiri(sig)
    kill sig, pid
  end
end
