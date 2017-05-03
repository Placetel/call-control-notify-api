require 'sinatra'
require 'builder'

set :bind, '0.0.0.0'
set :port, 3000

# Just a simple logger
post '/' do
  logger.info "event: #{params[:event]}"
  logger.info "call_id: #{params[:call_id]}"
  logger.info "from: #{params[:from]}"
  logger.info "to: #{params[:to]}"
end