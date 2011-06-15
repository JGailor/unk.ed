require 'em-synchrony'
require 'em-synchrony/em-redis'

config['redis'] = EM::Synchrony::ConnectionPool.new(:size => 10) do
  EM::Protocols::Redis.connect
end  