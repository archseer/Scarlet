require 'date'
require 'time'
require 'time-lord/version'
require 'time-lord/units'
require 'time-lord/units/business'
require 'time-lord/units/special'
require 'time-lord/units/long'
module TimeLord
  module Units
    TRUE_YEAR = 365.25 * DAY
  end
end

require 'time-lord/period'
require 'time-lord/scale'
require 'time-lord/time'
require 'time-lord/extensions/integer'
require 'active_support/core_ext/time'

class Scarlet
  module DateHelper
    # http://stackoverflow.com/questions/1904097/how-to-calculate-how-many-years-passed-since-a-given-date-in-ruby
    def calc_age(bd, d = Date.today)
      a = d.year - bd.year
      a = a - 1 if (
           bd.month >  d.month or
          (bd.month >= d.month and bd.day > d.day)
      )
      a
    end
  end
end

class Time
  # Since exists to replace TimeLords Time#ago, since the method is overriden
  # by active_support's time extension.
  #
  # @param [Time] time
  # @return [TimeLord::Period]
  def since(time = Time.now)
    # I've skipped the TimeLord::Time object since it served as a means to
    # pull a Period.
    TimeLord::Period.new(self, time)
  end
end

module TimeLord
  class Scale
    # I was wondering why Scale didn't have a to_s, its a very handy class
    #
    # @return [String]
    def to_s
      "#{to_value} #{to_unit}"
    end
  end

  class Period
    # Alias for to_words
    #
    # @return [String]
    alias :to_s :to_words

    # This exposes the Scale object used by the period
    #
    # @return [Scale]
    def scale
      # I hope they don't pull a "I TOLD YOU IT WAS PRIVATE"
      Scale.new(absolute)
    end
  end
end

class Integer
  # A nice way to convert an integer to a Scale
  #
  # @return [TimeLord::Scale]
  def timescale
    TimeLord::Scale.new(self)
  end
end
