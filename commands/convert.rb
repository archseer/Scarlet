require 'scarlet/helpers/http_command_helper'
require 'scarlet/helpers/json_command_helper'
require 'ostruct'

hear (/convert\s+(?<value>\d+.\d+|\d+)\s*(?<from>\w+)\s+(?:to\s+)?(?<to>\w+)/i) do
  clearance :any
  description 'Converts currency from one unit to another.'
  usage 'convert <value> <from-unit> [to] <to-unit>'
  helpers Scarlet::HttpCommandHelper, Scarlet::JsonCommandHelper
  on do
    q = { q: params[:value], from: params[:from], to: params[:to] }
    http = http_request("http://rate-exchange.appspot.com/currency").get(query: q)
    http.errback { reply 'Error!' }
    http.callback do
      data = OpenStruct.new(parse_json http.response)
      if err = data.err
        reply "err: #{err}"
      else
        reply "#{params[:value]} #{data.from} = #{data.v} #{data.to} (rate: #{data.rate})"
      end
    end
  end
end
