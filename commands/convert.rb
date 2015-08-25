require 'scarlet/helpers/http_helper'
require 'scarlet/helpers/json_command_helper'
require 'ostruct'

hear(/convert\s+(?<value>\d+.\d+|\d+)\s*(?<from>\w+)\s+(?:to\s+)?(?<to>\w+)/i) do
  clearance nil
  description 'Converts currency from one unit to another.'
  usage 'convert <value> <from_unit> [to] <to_unit>'
  helpers Scarlet::HttpHelper
  on do
    q = { q: params[:value], from: params[:from], to: params[:to] }
    http = json_request("http://rate-exchange.appspot.com/currency").get(query: q)
    http.errback { reply 'Error!' }
    http.callback do
      if http.response_header.http_status != 200
        reply "request error: Application might be down."
      else
        if v = http.response.value
          data = OpenStruct.new(v)
          if err = data.err
            reply "err: #{err}"
          else
            reply "#{params[:value]} #{data.from} = #{data.v} #{data.to} (rate: #{data.rate})"
          end
        else
          reply 'No response data'
        end
      end
    end
  end
end
