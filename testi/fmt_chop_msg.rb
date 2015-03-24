require 'lorem'
require 'scarlet/fmt'

log 'We are testing the chop_msg method'

chars = Lorem::Base.new('chars', 400).output
enum = Scarlet::Fmt.chop_msg chars
if enum.to_a != [chars]
  errorf 'Expected chop_msg to yield 1 String'
end

chars = Lorem::Base.new('chars', 800).output
enum = Scarlet::Fmt.chop_msg chars
unless enum.to_a.size == 2
  errorf 'Expected 2 chunks'
end
