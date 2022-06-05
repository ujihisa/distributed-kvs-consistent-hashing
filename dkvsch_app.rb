require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require './lib/dkvsch'

STORAGE = {}
PORTS = %w[3000 3001 3002]

def available_ports(self_port)
  PORTS.select {
    _1 == self_port or
      Net::HTTP.start('localhost', _1) { _1.head('/internal/ping').code == '200' } rescue false
  }
end

def startup(self_port)
  available_ports = available_ports(self_port) - [self_port]
  case available_ports.size
  when 0
    # You are the first person. Let's start from empty.
  when 1
    # You are the second person, and it should be at the world creation too.
  when 2
    # Ok you are likely recovering from a death, or the world creation. Let's assume it's recovery.
    port = DKVSCH.port_for_replicate(self_port, available_ports)
    STORAGE.merge!(
      JSON.parse(Net::HTTP.get(URI("http://localhost:#{port}/internal/dump-for-replicate.json"))))
  else
    raise 'Must not happen'
  end
end

startup(settings.port.to_s)
puts '---'
p settings.port
p STORAGE
puts '---'

head '/internal/ping' do
  @recoverying ? 503 : 200
end

get '/internal/dump-for-replicate.json' do
  STORAGE.to_json
end

get '/internal/get-bypass/:key' do
  STORAGE[params[:key]] || 404
end

post '/internal/post-bypass/:key' do
  STORAGE[params[:key]] = request.body.read
  STDOUT.puts "[#{request.port}] UPDATE #{params[:key]}=#{STORAGE[params[:key]]} at post-bypass"
  STDOUT.flush
  201
end

get '/:key' do
  available_ports = available_ports(request.port)
  raise 'Must not happen' if available_ports.size < 2

  port = DKVSCH.resolve(params[:key], available_ports)
  if request.port == port
    STORAGE[params[:key]] || 404
  else
    redirect "http://localhost:#{port}/internal/get-bypass/#{params[:key]}"
  end
end

post '/:key' do
  available_ports = available_ports(request.port)
  raise 'Must not happen' if available_ports.size < 2

  request_body = request.body.read()
  ports = DKVSCH.ports_for_write(params[:key], available_ports)
  ports.each do |port|
    Net::HTTP.post(
      URI("http://localhost:#{port}/internal/post-bypass/#{params[:key]}"),
      request_body)
  end
  201
end
