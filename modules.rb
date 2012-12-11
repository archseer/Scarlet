module Modules
  # Loads the models from the /models directory inside the specified root.
  def self.load_models root
    Dir["#{root}/models/**/*.rb"].each {|path| load path }
  end
  # Loads the library files from the /lib directory inside the specified root.
  def self.load_libs root
    Dir["#{root}/lib/**/*.rb"].each {|path| load path }
  end
end