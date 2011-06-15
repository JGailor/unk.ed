require 'goliath'
require 'haml'
require 'em-synchrony'
require 'em-synchrony/em-redis'
require 'base64'

class HomePage < Goliath::API  
  def render_response(path)
    @urls = env.redis.lrange("urls", 0, -1).map {|url| "/b/#{url}"}
    
    @Haml::Engine.new(File.open(path).read).render(self)
  end
  
  def response(env)
    [200, {"Content-Type" => "text/html"}, render_response("public/root.haml")]
  end
end

class ForwardingResponder < Goliath::API    
  def response(env)  
    params = env['PATH_INFO'].split('/') 
    [302, {"Location" => env.redis.get(params.last)}, ""]
  end
end

class LinkAdder < Goliath::API
  def response(env)
    key_val = env.redis.incr("url_shortener_key")
    uuid = Base64.urlsafe_encode64(key_val.to_s)  
    env.redis.set(uuid, params['unshortened_url'])
    env.redis.lpush('urls', uuid)
    [200, {}, env.redis.lrange("urls", 0, -1).join("\r\n")]
  end
end

class Server < Goliath::API
  use ::Rack::Reloader, 0 if Goliath.dev?
  
  map '/add' do
    use Goliath::Rack::Params
    run LinkAdder.new
  end
  
  map '/b' do    
    run ForwardingResponder.new
  end
  
  map '/' do
    use Goliath::Rack::Params
    run HomePage.new
  end  
end
