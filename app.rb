require "sinatra"
require 'sinatra/reloader' if development?
require "did_you_mean" if development?
require 'giphy'
require 'httparty'
require 'twilio-ruby'
require 'api-ai-ruby'
require 'json'

enable :sessions

configure :development do
  require 'dotenv'
  Dotenv.load
end

@client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
api = ApiAiRuby::Client.new(
    :client_access_token => ENV["CLIENT_ACCESS_TOKEN"]
)

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
  response = api.text_request "Rules"
  getMessage(response).to_s
  #getParameters(response).to_s + " " + getIntentName(response).to_s + " " + getName(response)
end

get "/state" do
  analyzed = api.text_request "Leaderboard"
  responce = determineResponce(analyzed)
  responce.to_s
end

get "/sms/incoming" do
  initializeSessions()
  body = params[:Body] || ""
  analyzed = api.text_request(body) || ""
  message, media = determineResponce(analyzed), nil
  responce = send_message(message,media)
  content_type 'text/xml'
  responce
end

# Sample Responces

#{:id=>"61b87aab-fb91-4a0b-b154-d1e3184946b1", :timestamp=>"2018-10-17T07:42:14.981Z", :lang=>"en", :result=>{:source=>"agent", :resolvedQuery=>"4", :action=>"", :actionIncomplete=>false, :parameters=>{:multiple=>"D"}, :contexts=>[], :metadata=>{:intentId=>"1ecb2512-a5ac-4333-97bd-274ba045c2f9", :webhookUsed=>"false", :webhookForSlotFillingUsed=>"false", :isFallbackIntent=>"false", :intentName=>"NEWANSWER"}, :fulfillment=>{:speech=>"", :messages=>[{:type=>0, :speech=>""}]}, :score=>1.0}, :status=>{:code=>200, :errorType=>"success"}, :sessionId=>"6c059abd-d21a-46db-8e77-c067348781eb"}

#{:id=>"5377d46c-5f8d-4bcd-b6ba-50bfb37b7ed4", :timestamp=>"2018-10-17T08:09:20.973Z", :lang=>"en", :result=>{:source=>"agent", :resolvedQuery=>"Name Jack", :action=>"", :actionIncomplete=>false, :parameters=>{:"given-name"=>"Jack"}, :contexts=>[], :metadata=>{:intentId=>"3e8fb6fa-5068-4b9c-ba74-09d165d55c8b", :webhookUsed=>"false", :webhookForSlotFillingUsed=>"false", :isFallbackIntent=>"false", :intentName=>"SETNAME"}, :fulfillment=>{:speech=>"", :messages=>[{:type=>0, :speech=>""}]}, :score=>1.0}, :status=>{:code=>200, :errorType=>"success"}, :sessionId=>"2506b052-d352-4cc6-863d-3d311a5ed56e"}

#{:id=>"0d987e63-6663-4f5f-bb32-c2a54f8b8aae", :timestamp=>"2018-10-17T08:36:50.397Z", :lang=>"en", :result=>{:source=>"agent", :resolvedQuery=>"Rules", :action=>"", :actionIncomplete=>false, :parameters=>{}, :contexts=>[], :metadata=>{:intentId=>"b79ab3cb-6ab4-48b2-88c1-245c653c3ffc", :webhookUsed=>"false", :webhookForSlotFillingUsed=>"false", :isFallbackIntent=>"false", :intentName=>"RULES"}, :fulfillment=>{:speech=>"Rules of Trivia Fighter is pretty simple. Just say 'Start Game' to text a new game or 'Leaderboard' to read more about the legendary trivia fighters!", :messages=>[{:type=>0, :speech=>"Rules of Trivia Fighter is pretty simple. Just say 'Start Game' to text a new game or 'Leaderboard' to read more about the legendary trivia fighters!"}]}, :score=>1.0}, :status=>{:code=>200, :errorType=>"success"}, :sessionId=>"f951dfcd-3116-42e3-88a4-783a44171e73"}

# Dialog Flow Stuff

def getParameters(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get Parameters: Responce is nil"
    return
  else
    return responce[:result][:parameters]
  end
end

def getIntentName(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get IntentName: Responce is nil"
    return
  else
    return responce[:result][:metadata][:intentName]
  end
end

def getName(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get Name: Responce is nil"
    return
  else
    if responce[:result][:parameters][:"given-name"].nil? || responce[:result][:parameters][:"given-name"].empty? || responce[:result][:parameters][:"given-name"] == ""
    puts "Cannot get Name: given-name is nil"
    return nil
    else
    return responce[:result][:parameters][:"given-name"]
    end
  end
end

def getAnswer(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get Answer: Responce is nil"
    return
  else
    if responce[:result][:parameters][:multiple].nil? || responce[:result][:parameters][:multiple].empty? || responce[:result][:parameters][:multiple] == ""
    puts "Cannot get Answer: multiple is nil"
    return nil
    else
    return responce[:result][:parameters][:multiple]
    end
  end
end

def getMessage(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get Message: Responce is nil"
    return nil
  else
    if responce[:result][:fulfillment][:speech].nil? || responce[:result][:fulfillment][:speech].empty? || responce[:result][:fulfillment][:speech] == ""
    puts "Cannot get Message: Speech is nil"
    return nil
    else
    return responce[:result][:fulfillment][:speech]
    end
  end
end

# Question Stuff

$difficulty = ["easy", "medium","hard"]
$question_type = ["boolean","multiple"]
$category = [9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28]

def get_question(amount, cat, diff, typ)
  if $difficulty.include?(diff) && $question_type.include?(typ) && $category.include?(cat) && amount.is_a?(Integer)
    responce = HTTParty.get("https://opentdb.com/api.php?amount=" + amount.to_s + "&category=" + cat.to_s + "&difficulty=" + diff + "&type=" + typ)
    if responce.success?
      parsed_JSON = JSON.parse(responce.body) rescue nil
      return parsed_JSON
      else
      puts "HTTParty is was not successfull: get_question"
      return
      end
  else
    puts "Function Input is Incorrect: get_question"
    return
  end
end

#Intent Functions

def determineResponce(body)
  message = ""
  intentName = getIntentName(body)
  case intentName
  when "RULES"
    message = rules()
  when "LEADERBOARD"
    message = leaderboard()
  when "STARTGAME"
    message = startgame()
  when "NEWQUESTION"
    message = newquestion()
  when "NEWANSWER"
    message = newanswer()
  when "ENDGAME"
    message = endgame()
  when "REPEATQUESTION"
    message = repeatquestion()
  when "SETNAME"
    message = setname()
  when "CURRENTSCORE"
    message = currentscore()
  else
    message = default()
  end
  return message
end

def default
  return "Welcome to Trivia Fighter Turbo!\nIf you don't know what to do just text 'Rules' to get yourself started."
end

def currentscore

end

def endgame

end

def leaderboard
  return "Here's the list you've been waiting for! \n1: Johnny Restless 15000 points \n2: John Doe 12500 points \n3: Jane Doe 11000 points \n4: Michael Scott 10000 points \n5: Muffin Man 9500 points. \nGet your game on to put your name on the list!"
end

def newanswer(ans)

end

def newquestion

end

def repeatquestion

end

# message, media = determineResponce(analyzed), nil
# responce = send_message(message,media)
# content_type 'text/xml'
# responce


def rules
  return "Rules of Trivia Fighter is pretty simple.\nJust text 'Start Game' to start a new game or text 'Leaderboard' to hear more about the legendary trivia fighters!"
end

def setname(str)

end

def startgame
  if session["game"] == false
    resetGame()
    session["game"] == true
    return "Welcome to Trivia Fighter, where the wise live to fight another day and trivia legends are born!\nYou just took your first step to greatness. Text 'New Question' to face your next challenge or 'Repeat question' to hear a question once again.\nTo test your judgement, just say 'The answer is' followed by your letter of choice: A, B, C or D."
  else
    return "It looks like you are already on a Trivia Fighter quest.\nEither face your new challenge by saying 'Next Question' or give up by saying 'End Game'.\nYou can check your current score by simply saying 'Current Score'"
  end
end

#Session Functions

def setGameState(bool)
  if !!bool == bool
    session["game"] = bool
  else
  puts "setGameState Failed: bool isn't a boolean"
  end
end

def setQLoad(bool)
  if !!bool == bool
    if session["game"] == true
    session["game"] = bool
    else
      puts "setQload Failed: session['game'] = false"
      return
    end
  else
  puts "setQLoad Failed: bool isn't a boolean"
  end
end

def increaseScore(scr)
  if (!scr.is_a?(Integer)) || points <= 0
    puts "increaseScore failed: Incorrect scr"
    return
  else
    session["score"] = session["score"] + points
    return session["score"]
  end
end

def setPlayerName(str)
  if str.nil? || (!str.is_a?(String)) || str == ""
    puts "setPlaerName Failed: Incorrect str"
    return
  else
    session["name"] = str
    return session["name"]
  end
end

def setAnswer(ans)
  if ans != "A" || ans != "B" || ans != "C" || ans != "D" || !ans.is_a(String)
    puts "setAnswer Failed: Incorrect ans"
    return
  else
    session["answer"] = ans
    return session["answer"]
  end
end

def setChoices(chs)
  if quest.is_a?(Array)
    session["choices"] = chs
    return session["choices"]
  else
    puts "setChoices Failed: Incorrect chs"
    return
  end
end

def setQuestion(quest)
  if quest.is_a?(String)
    session["question"] = quest
    return session["question"]
  else
    puts "setQuestion Failed: Incorrect quest"
    return
  end
end

def resetGame()
  session["score"] = 0
  session["game"] = false
  session["qload"] = false
end

def initializeSessions()
  if session["score"].nil?
    session["score"] = 0
  end
  if session["name"].nil?
    session["name"] = ""
  end
  if session["question"].nil?
    session["question"] = ""
  end
  if session["choices"].nil?
    session["choices"] = []
  end
  if session["answer"].nil?
    session["answer"] = ""
  end
  if session["game"].nil?
    session["game"] = false
  end
  if session["qload"].nil?
    session["qload"] = false
  end
end
