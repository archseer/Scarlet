module Modules
  def self.load_models root
    Dir["#{root}/models/**/*.rb"].each {|path| load path }
  end

  def self.load_libs root
    Dir["#{root}/lib/**/*.rb"].each {|path| load path }
  end
end