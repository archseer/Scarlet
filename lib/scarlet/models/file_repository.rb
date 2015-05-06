require 'thread'
require 'thread_safe'
require 'yaml'
require 'moon-repository/load'

class Moon::Storage::Base
  def post_initialize
    @sync_m = Mutex.new
  end

  def synchronize(&block)
    @sync_m.synchronize(&block)
  end
end
