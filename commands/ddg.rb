require 'scarlet/helpers/http_helper'

# @param [Hash<String, String>] data
# @yieldparam [String] line
def format_abstract(data)
  heading = data['Heading'].presence
  url = data['AbstractURL'].presence || data['Redirect'].presence
  head = ''
  head << heading << ' ' if heading
  head << fmt.uri(url) if url
  yield head if head.present?
  if text = data['AbstractText'].presence
    if source = data['AbstractSource'].presence
      yield source + "; " + text
    else
      yield text
    end
  end
end

# @param [Hash<String, String>] data
# @yieldparam [String] line
def format_answer(data)
  head = ''
  head << data['AnswerType'] << "; " << data['Answer']
  yield head
end

# @param [Hash<String, String>] data
# @yieldparam [String] line
def format_definition(data)
  url = data['DefinitionURL'].presence || data['Redirect'].presence
  head = ''
  head << fmt.uri(url) if url
  yield head if head.present?
  if text = data['Definition'].presence
    if source = data['DefinitionSource'].presence
      yield source + "; " + text
    else
      yield text
    end
  end
end

# @param [String] search_terms
def ddg(search_terms)
  q = CGI.escape(search_terms)
  query = { q: q, format: 'json', no_html: 1 }
  http = json_request('https://api.duckduckgo.com').get query: query
  http.errback { reply 'Error!' }
  http.callback do
    if data = http.response.value
      func = -> (line) { reply line }
      if data['Abstract'].present?
        format_abstract(data, &func)
      elsif data['Definition'].present?
        format_definition(data, &func)
      elsif data['Answer'].present?
        format_answer(data, &func)
      else
        reply 'Quack! No results!'
      end
    else
      reply 'Invalid response data'
    end
  end
end

hear(/ddg\s+(?<search_term>.+)/i) do
  clearance nil
  description 'Search for something using DuckDuckGo.'
  usage 'ddg <search_term>'
  helpers Scarlet::HttpHelper
  on do
    ddg params[:search_term].strip
  end
end
