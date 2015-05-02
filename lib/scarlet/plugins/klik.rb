module Scarlet
  module Klik
    def self.klik
      @klik ||= [Time.now, Time.now]
      @klik[0] = Time.now - @klik[1]
      @klik[1] = Time.now
      @klik[0]
    end
  end
end
