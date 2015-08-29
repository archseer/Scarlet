require 'scarlet/js_object_parser'
require 'scarlet/helpers/http_command_helper'

# The echo command is simply used for checking if the bot exists, or for testing
# message sending.
hear (/translate (?::(?<origin>\w+))? (?<msg>.+)/) do
  clearance nil
  description 'Translates given message.'
  usage 'translate <message>'
  helpers Scarlet::HttpCommandHelper
  on do
    origin = params[:origin] || 'auto'
    target = 'en'
    term = CGI.escape(params[:msg])
    query = {
        client: 't',
        hl: 'en',
        sl: origin,
        ssel: 0,
        tl: target,
        tsel: 0,
        q: term,
        ie: 'UTF-8',
        oe: 'UTF-8',
        otf: 1,
        dt: ['bd', 'ex', 'ld', 'md', 'qca', 'rw', 'rm', 'ss', 't', 'at']
    }
    http = plaintext_request('https://translate.google.com/translate_a/single').get query: query
    http.errback { reply 'Error!' }
    http.callback do
      if str = http.response.value
        begin
          data = Scarlet::JsObjectParser.parse(str)
          reply data.inspect
        rescue Scarlet::JsObjectParser::ParserJam => ex
          reply "ERROR: #{ex.inspect}"
        end
      else
        reply 'Invalid response data'
      end
    end
  end
end
