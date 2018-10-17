require "sinatra"
require 'sinatra/reloader' if development?
require "did_you_mean" if development?
require 'giphy'
require 'httparty'
require 'twilio-ruby'
require 'api-ai-ruby'

enable :sessions

configure :development do
  require 'dotenv'
  Dotenv.load
end

@client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
api = ApiAiRuby::Client.new(
    :client_access_token => ENV["CLIENT_ACCESS_TOKEN"]
)

#{:id=>"61b87aab-fb91-4a0b-b154-d1e3184946b1", :timestamp=>"2018-10-17T07:42:14.981Z", :lang=>"en", :result=>{:source=>"agent", :resolvedQuery=>"4", :action=>"", :actionIncomplete=>false, :parameters=>{:multiple=>"D"}, :contexts=>[], :metadata=>{:intentId=>"1ecb2512-a5ac-4333-97bd-274ba045c2f9", :webhookUsed=>"false", :webhookForSlotFillingUsed=>"false", :isFallbackIntent=>"false", :intentName=>"NEWANSWER"}, :fulfillment=>{:speech=>"", :messages=>[{:type=>0, :speech=>""}]}, :score=>1.0}, :status=>{:code=>200, :errorType=>"success"}, :sessionId=>"6c059abd-d21a-46db-8e77-c067348781eb"}

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
  response = api.text_request "4"
  response.to_s
end

get "/state" do

end

get "/sms/incoming" do
  body = params[:Body] || ""
  if session["str"].nil?
    session["str"] = ""
  end  
  message, media = "hello" + session["str"], nil
  responce = send_message(message,media)
  session["str"] = body
  content_type 'text/xml'
  responce
end
