#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require 'pp'

module CometData
  @comet_responses = {}
  
  def self.comet_responses
    @comet_responses
  end
end

class CometServer < EM::Connection
  include EM::HttpServer

   def post_init
     super
     no_environment_strings
   end


   def process_http_request
    # the http request details are available via the following instance
    # variables:
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_headers
    if @http_request_uri == '/comet/'
      return process_comet_request
    end

    if @http_request_uri == '/'
      @http_request_uri = '/index.html'
    end
    
    response = EM::DelegatedHttpResponse.new(self)
    begin
      File.open(@http_request_uri.sub(/^\//, ''), 'r') do |file|
        response.status = 200
        response.content_type 'text/html'
        response.content = file.read()
      end
    rescue
      response.status = 404
      response.content_type 'text/html'
      response.content = '404 not found'
    end
    response.send_response
  end
  
  def process_comet_request
    incoming_messages = JSON.parse(@http_post_content)
    nick = incoming_messages.first
    puts "incoming messages"
    pp incoming_messages
    
    if incoming_messages.size > 1
      puts "sending all users #{incoming_messages.inspect}"
      CometData::comet_responses.each do |key, val|
        resp, timer = val
        send_in_response(resp, incoming_messages)
        EventMachine::cancel_timer(timer)
        CometData::comet_responses.delete(key)
      end
    end

    # if @comet_responses.has_key?(nick)
    #   response = @comet_responses[nick]
    #   send_in_response(response, [])
    # end
    response = EM::DelegatedHttpResponse.new(self)
    timer = EventMachine::add_timer(30) do
      send_in_response(response, [])
    end  
    CometData::comet_responses[nick] = [response, timer]
  end
  
  def send_in_response(response, data)
    response.status = 200
    response.content_type 'application/json'
    response.content = data.to_json
    response.send_response
  end
  
end

EM.run{
  EM.start_server '0.0.0.0', 8080, CometServer
}
