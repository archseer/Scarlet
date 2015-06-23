require 'scarlet/helpers/http_command_helper'

# @param [Hash<String, String>] data
# @yieldparam [String] line
format_abstract = lambda do |ctx, data, &block|
  heading = data['Heading'].presence
  url = data['AbstractURL'].presence || data['Redirect'].presence
  head = ''
  head << heading << ' ' if heading
  head << ctx.fmt.uri(url) if url
  block.call head if head.present?
  if text = data['AbstractText'].presence
    if source = data['AbstractSource'].presence
      block.call source + "; " + text
    else
      block.call text
    end
  end
end

# @param [Hash<String, String>] data
# @yieldparam [String] line
format_answer = lambda do |ctx, data, &block|
  block.call data['AnswerType'] + "; " + data['Answer']
end

# @param [Hash<String, String>] data
# @yieldparam [String] line
format_definition = lambda do |ctx, data, &block|
  url = data['DefinitionURL'].presence || data['Redirect'].presence
  head = ''
  head << ctx.fmt.uri(url) if url
  block.call head if head.present?
  if text = data['Definition'].presence
    if source = data['DefinitionSource'].presence
      block.call source + "; " + text
    else
      block.call text
    end
  end
end

# @param [Object] ctx
# @param [String] search_terms
ddg = lambda do |ctx, search_terms|
  q = CGI.escape(search_terms)
  query = { q: q, format: 'json', no_html: 1 }
  http = ctx.json_request('https://api.duckduckgo.com').get query: query
  http.errback { ctx.reply 'Error!' }
  http.callback do
    if data = http.response.value
      func = if data['Abstract'].present?
        format_abstract
      elsif data['Answer'].present?
        format_answer
      elsif data['Definition'].present?
        format_definition
      else
        ctx.reply 'Quack! No results!'
        nil
      end
      func.call(ctx, data) { |line| ctx.reply line } if func
    else
      ctx.reply 'Invalid response data'
    end
  end
end

hear (/ddg\s+(?<search_term>.+)/) do
  clearance :any
  description 'Search for something using DuckDuckGo.'
  usage 'ddg <search_term>'
  helpers Scarlet::HttpCommandHelper
  on do
    ddg.call self, params[:search_term].strip
  end
end
