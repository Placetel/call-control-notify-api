require 'sinatra'
require 'builder'

set :bind, '0.0.0.0'
set :port, 3000

post '/' do
  logger.info "event: #{params[:event]}"
  logger.info "call_id: #{params[:call_id]}"
  logger.info "from: #{params[:from]}"
  logger.info "to: #{params[:to]}"

  headers 'Content-Type' => 'application/xml'
  xml = Builder::XmlMarkup.new(indent: 4)
  xml.instruct!

  # Forward to voicemail
  xml.Response{
    xml.Forward(voicemail: true)
  }
end