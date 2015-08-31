class Scarlet
  module Version
    MAJOR, MINOR, TEENY, PATCH = 1, 7, 0, nil
    STRING = [MAJOR, MINOR, TEENY, PATCH].compact.join('.').freeze
  end
  VERSION = Version::STRING
end
