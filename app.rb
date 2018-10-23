require "sinatra"
require 'sinatra/activerecord'
require 'sinatra/reloader' if development?
require "did_you_mean" if development?
require 'giphy'
require 'httparty'
require 'twilio-ruby'
require 'api-ai-ruby'
require 'json'
require_relative './models/task'

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

# LINKS FOR TESTING

get "/" do
	404
end

get "/test" do
  response = api.text_request "Answer A"
  ans = getAnswer(response)
  #getParameters(response).to_s + " " + getIntentName(response).to_s + " " + getName(response)
  k = session["choices"].index(session["answer"])
  ind = index_to_choi(k)
  if ind == ans
    increaseScore(100)
    setQLoad(false)
    "Correct Answer!\nCurrent Score:" + session["score"].to_s + "\nType 'Next Question' to continue!"
  else
    message = "Incorrect Answer!\nFinal Score: " + session["score"].to_s + "\nCorrect answer was " + session["answer"] + "\nIf you want more just type 'New Game' again and maybe you will get lucky this time!"
    resetGame()
    message
  end
end

get "/state" do
  quest = get_question(1,$category.sample,$difficulty[0],"multiple")
  setQuestion(get_query(quest))
  setChoices(get_choices(quest))
  setAnswer(get_answer(quest))
  k = session["choices"].index(session["answer"])
  ind = index_to_choi(k)
  session["question"] + session["choices"].to_s
end

get "/tasks"  do
  items = Task.all.order(score: :desc)
  items.empty?.to_s + " " + checkBoardSize().to_s

  # items = Task.all.order(score: :desc).size
  # items.to_s
end

get "/destroy"  do
  # Task.delete_all
  "Destroy"
end

get "/getMinScore" do
  # addScore("Nate",400)
  # addScore("John",500)
  # addScore("Donna",200)
  # addScore("Mark",100)
  checkBoardSize().to_s
  #deleteLastScore()
end

get "/list_tasks" do
  list = Task.all.order(score: :desc).last.to_json
  parsed = JSON.parse(list)
  parsed["name"].to_s + " " + parsed["score"].to_s + " points"
end

get "/hash" do
  #list = Task.all.order(score: :desc).to_json
  #parsed = JSON.parse(list)
  # parsed = getScoreBoard()
  # bs = checkBoardSize()
  # a = ""
  # for i in 0..(bs-1)
  #  a = a + parsed[i]["score"].to_s
  # end
  # a
  #newScore("Douglas",300)
  leaderboard()
  #getMinScore().to_s
end

get "/time" do
  initializeSessions()
  session["time"].to_s
end

get "/diff" do
  checkTimeDiff(session["time"],Time.new()).to_s
end

# FUNCTIONS FOR DATABASE OPERATIONS

#Return message string with using the data leaderboard
def printLeaderArray()
  #"Here's the list of legendary fighters who overpowered the trivia beasts like no other! \n1: Johnny Restless 15000 points \n2: John Doe 12500 points \n3: Jane Doe 11000 points \n4: Michael Scott 10000 points \n5: Muffin Man 9500 points. \nEmbark on your own journey to rise through the ranks!"
  a = makeLeaderArray()
  b = "Here's the list of legendary fighters who overpowered the trivia beasts like no other!"
  bs = checkBoardSize()
  if bs < 1
    b = "No warrior was worthy enough to make it to the list yet. Type 'Start Game' to be the first to try!"
  else
    a.each.with_index do |item, index|
    b = b + " \n"+ (index+1).to_s + " - " + item[0] + " " + item[1] + " points"
    end
    b = b + "\nEmbark on your own journey to rise through the ranks!"
  end
  return b
end

#Returns an array of arrays where each enrty
def makeLeaderArray()
  a = []
  bs = checkBoardSize()
  if bs > 0
    parsed = getScoreBoard()
    for i in 0..(bs-1)
      a.append([parsed[i]["name"],parsed[i]["score"].to_s])
    end
  end
  return a
end

#Returns parsed list from database
def getScoreBoard()
  bs = checkBoardSize()
  if bs < 1
    return []
  else
    list = Task.all.order(score: :desc).to_json
    parsed = JSON.parse(list)
    return parsed
  end
end

#Adds Score to Leaderboard database
def addScore(name,scr)
  if name.is_a?(String) && scr.is_a?(Integer)
    s = Task.create(name: name, score: scr)
    return
  else
    return
  end
end

#Returns the number of entries on leaderboard database
def checkBoardSize()
  return Task.all.size
end

#Returns the score with the minimum value from leaderboard database
def getMinScore()
  if Task.all.empty?
    return 0
  else
      list = Task.all.order(score: :desc).last
      #parsed = JSON.parse(list)
      score = list["score"]
      return score
      #parsed["score"]
  end
end

#Deletes entry with the minimum score value
def deleteLastScore()
  return Task.all.order(score: :desc).last.delete
end

#Adds new entry to database if the new entry qualifies
def newScore(name,scr)
  if name.is_a?(String) && scr.is_a?(Integer)
    bs = checkBoardSize()
    if bs < 5
      addScore(name,scr)
      return true
    else
      ms = getMinScore()
      if scr > ms
        deleteLastScore()
        addScore(name,scr)
        return true
      else
        return false
      end
    end
  else
    puts "saveScore failes: Input Error"
    return false
  end
end

# MAIN

get "/sms/incoming" do
  initializeSessions()
  body = params[:Body] || ""
  analyzed = api.text_request(body) || ""
  message, media = determineResponce(analyzed), nil
  responce = send_message(message,media)
  content_type 'text/xml'
  responce
end

# DIALOGFLOW STUFF

#Returns parameters using DialogFlow responce
def getParameters(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get Parameters: Responce is nil"
    return
  else
    return responce[:result][:parameters]
  end
end

#Returns Intent name using Dialogflow responce
def getIntentName(responce)
  if responce.nil? || responce.empty?
    puts "Cannot get IntentName: Responce is nil"
    return
  else
    return responce[:result][:metadata][:intentName]
  end
end

#Returns name entered by user from Diagloflow responce
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

#Returns value of answer by user from Dialogflow responce
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

#Returns
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

# TIME RELATED STUFF

#Checks time difference between to datetime objects and returns true if difference smaller than 2 minutes
def checkTimeDiff(t_start,t_end)
  t1 = t_start.to_i
  t2 = t_end.to_i
  t3 = t2 - t1
  if t3 > 120
    return false
  else
    return true
  end
end

# Question STUFF

$difficulty = ["easy", "medium"] #"hard"]
$question_type = ["boolean","multiple"]
$category = [9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28]

#Gets question from Open Trivia Database using parameters
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

#Returns question string from Open Trivia DB json responce
def get_query(question)
    if question.nil? || question.empty?
      return nil
    else
      que = question["results"][0]["question"]
      if que.nil?
        return nil
      else
      return que
      end
    end
  end

#Returns answer string from Open Trivia DB json responce
def get_answer(question)
    if question.nil? || question.empty?
      return nil
    else
      ans = question["results"][0]["correct_answer"]
      if ans.nil?
        return nil
      else
      return ans
      end
    end
end

#Returns choices array from Open Trivia DB json responce
def get_choices(question)
  choi = []
  if question.nil? || question.empty?
    return nil
  else
    choi.push(question["results"][0]["correct_answer"])
    question["results"][0]["incorrect_answers"].each do |item|
      choi.push(item)
    end
    if choi.nil? || choi.empty?
      return nil
    else
    return choi.shuffle
    end
  end
end

#Function migrated from older project
def determine_answer(ans,choi)
  for i in 0..3
    if choi[i] == ans
      puts i.to_s + " " + choi[i]
      return i_to_ans(i)
    end
  end
end

#Converts index of array to characters A,B,C,D
def index_to_choi(int)
  case int
  when 0
    return 'A'
  when 1
    return 'B'
  when 2
    return 'C'
  when 3
    return 'D'
  else
    return 'E'
  end
end

# INTENT FUNCTIONS

#Gets intent name as string and returns necessary responce string using functions below
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
    message = newanswer(getAnswer(body).to_s)
  when "ENDGAME"
    message = endgame()
  when "REPEATQUESTION"
    message = repeatquestion()
  when "SETNAME"
    message = setname(getName(body).to_s)
  when "CURRENTSCORE"
    message = currentscore()
  else
    message = default()
  end
  return message
end

def default
  return "Welcome to Trivia Fighter Turbo!\nIf you don't know what to do just text 'Rules' to learn more or text 'New Game' to challenge the cunning trivia monsters!"
end

def currentscore
  if session["game"] == true
    return "Current Score: " + session["score"].to_s
  else
    return "Crushing the trivia monsters is no easy task.\nType 'Start Game' first, to be worthy of a score"
  end
end

def endgame
  if session["game"] == true
    message = "Final Score: " + session["score"].to_s + "\nIf you want to play more just type 'New Game' any time and test your skills against the trivia demons!"
    if session["name"] == "" or session["name"].nil?
      message = message + "\nAlso don't forget to set your name if you want to make it to the leaderboard."
    else
      bool = newScore(session["name"],session["score"])
      if bool
        message = message + "\nType 'Leaderboard' to see your name on the wall!"
      end
    end
    resetGame()
    return message
  else
    return "You can't quit without even trying.\nA legendary quest call upon you!\nReply 'Start Game' to face the trivia demons."
  end
end

def leaderboard
  b = "Here's the list of legendary fighters who overpowered the trivia beasts like no other!"
  bs = checkBoardSize()
  if bs < 1
    b = "No warrior was worthy enough to make it to the list yet.\nType 'Start Game' to be the first to try but don't forget to set your name first by typing 'Set Name [Insert A Name Here]'!"
  else
    a = makeLeaderArray()
    a.each.with_index do |item, index|
    b = b + " \n"+ (index+1).to_s + " - " + item[0] + " " + item[1] + " points"
    end
    b = b + "\nEmbark on your own journey to rise through the ranks!"
  end
  return b
  #"Here's the list of legendary fighters who overpowered the trivia beasts like no other! \n1: Johnny Restless 15000 points \n2: John Doe 12500 points \n3: Jane Doe 11000 points \n4: Michael Scott 10000 points \n5: Muffin Man 9500 points. \nEmbark on your own journey to rise through the ranks!"
end

def newanswer(ans)
  if session["game"] == true
    if session["qload"] == true
      k = session["choices"].index(session["answer"])
      ind = index_to_choi(k)
      tim = checkTimeDiff(session["time"],Time.new())
      if ind == ans && tim
        increaseScore(100)
        setQLoad(false)
        return "Correct Answer!\nCurrent Score: " + session["score"].to_s + "\nType 'Next Question' to continue!"
      else
        message = "\nFinal Score: " + session["score"].to_s + "\nCorrect answer was " + session["answer"] + "\nIf you want more just type 'New Game' again and maybe you will get lucky this time!"
        if !tim
          message = "Too Late!" + message
        else
          message = "Incorrect Answer!" + message
        end
        if session["name"] == "" or session["name"].nil?
          message = message + "\nAlso don't forget to set your name if you want to make it to the leaderboard."
        else
          bool = newScore(session["name"],session["score"])
          if bool
            message = message + "\nType 'Leaderboard' to see your name on the wall!"
          end
        end
        resetGame()
        return message
      end
    else
      return "It seems like you haven't asked for youe next challange yet!\nText 'Next Question' to face tour destiny!"
    end
  else
    return "You haven't started a game yet!\nSay 'Start Game' first to face your trivia demons."
  end
end

def newquestion
  if session["game"] == true
    #Game is in play
    if session["qload"] == true
      #Already have question
      return "It appears to me that you haven't answered your previous question yet!\nAnswer that the question at hand first, to face a new challenge.\nTime is running out!"
    else
      setQLoad(true)
      quest = get_question(1,$category.sample,$difficulty.sample,"multiple")
      setQuestion(get_query(quest))
      setChoices(get_choices(quest))
      setAnswer(get_answer(quest))
      setTime()
      return "Question: " + session["question"] + "\nA - " + session["choices"][0] + "\nB - " + session["choices"][1] + "\nC - " + session["choices"][2] + "\nD - " + session["choices"][3]
    end
  else
    return "You haven't started a game yet!\nSay 'Start Game' first to face your trivia demons."
  end
end

def repeatquestion
  if session["game"] == true && session["qload"] == true
    return "Question: " + session["question"] + "\nA - " + session["choices"][0] + "\nB - " + session["choices"][1] + "\nC - " + session["choices"][2] + "\nD - " + session["choices"][3]
  else
    return "A worthy fighter knows when to accept mistakes but never cheats!\n'Type 'Next Question' to reveal your faith."
  end
end

def rules
  return "Rules of Trivia Fighter are simple.\nJust text 'Start Game' if you are ready to be challenged or text 'Leaderboard' to hear more the tales legendary trivia fighters who roamed these lands before you!"
end

def setname(str)
  setPlayerName(str)
  return "Player name set to " + session["name"]
end

def startgame
  if session["game"] == false
    resetGame()
    setGameState(true)
    return "Welcome to Trivia Fighter, where the wise live to fight another day and trivia legends are born!\nYou just took your first step to greatness. Text 'New Question' to face your next challenge or 'Repeat question' to hear a question once again.\nTo test your judgement, just say 'The answer is' followed by your letter of choice: A, B, C or D.\nYou will have two minutes to answer each question."
  else
    return "It looks like you are already on a Trivia Fighter quest.\nEither face your new challenge by saying 'Next Question' or give up by saying 'End Game'.\nYou can check your current score by simply saying 'Current Score'"
  end
end

# SESSION FUNCTIONS

#Setter Function for session["game"]
def setGameState(bool)
  if !!bool == bool
    session["game"] = bool
  else
  puts "setGameState Failed: bool isn't a boolean"
  end
end

#Setter Function for session["qload"]
def setQLoad(bool)
  if !!bool == bool
    if session["game"] == true
    session["qload"] = bool
    else
      puts "setQload Failed: session['game'] = false"
      return
    end
  else
  puts "setQLoad Failed: bool isn't a boolean"
  end
end

#Increases session["score"] by the amount of scr
def increaseScore(scr)
  if (!scr.is_a?(Integer)) || scr <= 0
    puts "increaseScore failed: Incorrect scr"
    return
  else
    session["score"] = session["score"] + scr
    return session["score"]
  end
end

#Setter Function for session["name"]
def setPlayerName(str)
  if str.nil? || (!str.is_a?(String)) || str == ""
    puts "setPlaerName Failed: Incorrect str"
    return
  else
    session["name"] = str
    return session["name"]
  end
end

#Setter Function for session["answer"]
def setAnswer(ans)
  if !ans.is_a?(String)
    puts "setAnswer Failed: Incorrect ans"
    session["answer"] = "A"
    return
  else
    session["answer"] = ans
    return session["answer"]
  end
end

#Setter Function for session["choices"] which is an array
def setChoices(chs)
  if chs.is_a?(Array)
    session["choices"] = chs
    return session["choices"]
  else
    puts "setChoices Failed: Incorrect chs"
    return
  end
end

#Setter Function for session["question"]
def setQuestion(quest)
  if quest.is_a?(String)
    session["question"] = quest
    return session["question"]
  else
    puts "setQuestion Failed: Incorrect quest"
    return
  end
end

#Resets session["score"], session["game"], session["qload"]
def resetGame()
  session["score"] = 0
  session["game"] = false
  session["qload"] = false
end

#Sets session["time"] to Time.new()
def setTime()
  session["time"] = Time.new()
end

#Initializes session variables
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
  if session["time"].nil?
    session["time"] = Time.new()
  end
end
