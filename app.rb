require "sinatra"
require 'sinatra/reloader' if development?

require 'twilio-ruby'
require 'api-ai-ruby'

enable :sessions

@client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
api = ApiAiRuby::Client.new(
    :client_access_token => ENV["CLIENT_ACCESS_TOKEN"]
)

configure :development do
  require 'dotenv'
  Dotenv.load
end

#Gets text and media string to send a message through Twilio
def send_message(text,media)
  if text.nil? || text == ""
    return nil
  else
    twiml = Twilio::TwiML::MessagingResponse.new do |r|
      r.message do |m|
    		# add the text of the response
        m.body(text)
    		# add media if it is defined
        unless media.nil?
          m.media(media)
        end
      end
    end
  end
  #send a response to twilio
  return twiml.to_s
end

get "/" do
	404
end

get "/test" do
  response = api.text_request 'hello!'
  response.to_s
end

get "/sms/incoming" do
  body = params[:Body] || ""
  message, media = "hello", nil
  responce = send_message(message,media)
  content_type 'text/xml'
  responce
end
