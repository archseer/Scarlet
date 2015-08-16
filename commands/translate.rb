# The echo command is simply used for checking if the bot exists, or for testing
# message sending.
hear (/translate (?<msg>.+)/) do
  clearance nil
  description 'Translates given message.'
  usage 'translate <message>'
  on do
    origin = 'auto'
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
    http = ctx.json_request('https://translate.google.com/translate_a/single').get query: query
    http.errback { ctx.reply 'Error!' }
    http.callback do
      reply 'Invalid response data'
    end
  end
end
