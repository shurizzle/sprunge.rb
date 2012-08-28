require 'sinatra'
require 'redis'
require 'coderay'

ALPHABET = ('A'..'Z').to_a + ('a'..'z').to_a

helpers do
  def redis
    @r ||= Redis.new
  end

  def get_random_key
    keys = redis.keys('[a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z]')
    if keys.size == 7311616
      keys.first
    else
      key = nil
      begin
        key = 4.times.map { ALPHABET.shuffle[rand(0..51)] }.join
      end while keys.include?(key)
      key
    end
  end
end

get '/' do
  headers 'Content-Type' => 'text/plain'
  body 'SHURIZZLE GAY'
end

post '/' do
  headers 'Content-Type' => 'text/plain'
  content = request.POST['sprunge']
  unless content.empty?
    key = get_random_key
    redis[key] = content
    body key
  end
end

get '/:id' do
  b = redis[params[:id]]
  if b
    lang = request.env['QUERY_STRING'].strip
    lang = CodeRay::FileType::TypeFromExt[lang] || CodeRay::FileType::TypeFromExt[lang.downcase] || lang
    if lang.empty?
      headers 'Content-Type' => 'text/plain'
      body b
    else
      body CodeRay.scan(b, lang).html(:wrap => :page, :line_numbers => :table, :line_number_anchors => 'n-', :tab_width => 2, :title => params[:id])
    end
  else
    ''
  end
end
