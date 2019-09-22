require 'sinatra'
require 'net/http'
require 'uri'
require './lib/dkvsch'

STORAGE = {}
PORTS = %w[3000 3001 3002]

def available_ports(self_port)
  PORTS.select {
    @1 == self_port or
      Net::HTTP.start('localhost', @1) { @1.head('/internal/ping').code == '200' } rescue false
  }
end

head '/internal/ping' do
  200
end

get '/internal/get-bypass/:key' do
  STORAGE[params[:key]] || 404
end

post '/internal/post-bypass/:key' do
  STORAGE[params[:key]] = p request.body.read
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

  ports = DKVSCH.ports_for_write(params[:key], available_ports)
  ports.each do |port|
    if request.port == port
      STORAGE[params[:key]] = request.body.read
    else
      Net::HTTP.post(
        URI("http://localhost:#{port}/internal/post-bypass/#{params[:key]}"),
        request.body.read)
    end
  end
  201
end
