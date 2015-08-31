class Scarlet
  module Git
    def self.get_data
      {
        commit: `git rev-parse HEAD`.chomp,
        branch: `git rev-parse --abbrev-ref HEAD`.chomp
      }
    end

    def self.data
      @data ||= get_data
    end
  end
end
