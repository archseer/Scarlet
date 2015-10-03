require 'scarlet/helpers/http_helper'
require 'ostruct'

hear(/to_hex\s+(?<number>\d+)/) do
  clearance nil
  description 'Converts an integer to hexadecimal'
  usage 'to_hex <number>'
  on do
    num = params[:number].to_i
    reply "%d : %x" % [num, num]
  end
end

hear(/convert\s+(?<value>\d+.\d+|\d+)\s*(?<from>\w+)\s+(?:to\s+)?(?<to>\w+)/i) do
  clearance nil
  description 'Converts currency from one unit to another.'
  usage 'convert <value> <from_unit> [to] <to_unit>'
  helpers Scarlet::HttpHelper
  on do
    q = { base: params[:from] }
    http = json_request("http://api.fixer.io/latest").get(query: q)
    http.errback { reply 'Error!' }
    http.callback do
      v = http.response.value
      if v && (err = v['error'])
        reply "ERROR: #{err}"
      elsif v
        base = v['base']
        dest = params[:to].upcase
        if rate = v['rates'][dest]
          value = params[:value].to_f
          dest_value = (value * rate).round(2)
          reply "#{value} #{base} = #{dest_value} #{dest} (rate: #{rate})"
        else
          reply "I'm sorry, I couldn't find currency rate for #{dest}"
        end
      else
        reply 'No response data'
      end
    end
  end
end
