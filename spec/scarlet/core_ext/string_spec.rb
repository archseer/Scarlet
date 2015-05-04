require 'spec_helper'
require 'scarlet/core_ext/string'

describe String do
  context '#word_wrap' do
    it 'wraps a string around the given width' do
      str = %Q(Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Vivamus vitae risus vitae lorem iaculis placerat. Aliquam sit amet felis. Etiam congue.)
      actual = str.word_wrap(40)
      expect(actual).to eq "Lorem ipsum dolor sit amet, consectetuer\nadipiscing elit. Vivamus vitae risus\nvitae lorem iaculis placerat. Aliquam\nsit amet felis. Etiam congue.\n"
    end
  end

  context '#irc_color' do
    it 'adds irc color codes to the string' do
      str = 'Colorize me baby'
      actual = str.irc_color 1, 2
      expect(actual).to eq("\x0301,02Colorize me baby\x03")
    end
  end
end
