# TRIVIA-FIGHTER-TURBO

![picture](https://github.com/cemergin/TRIVIA-FIGHTER-TURBO/blob/master/images/Super-Smash-Bros-1.jpg)

Are you ready to fulfill your destiny and become the greatest trivia fighter of all time? Then the adventure you seek is just a text message away!

The goal of this project is to develop a text-based trivia game that allows players to test their skills and knowledge as they compete for the #1 spot on the leaderboard. 

..and you guessed it is heavily influenced by the timeless classic Street Fighter!

Final Command List: New Game, Next Question, Answer is A, Repeat Question, Rules, Leaderboard, End Game, Current Score

Technologies Involved: Ruby, Sinatra, Dialogflow, Twilio, Heroku, Postgres, httparty

Intention
Computer games have become an integral part of our daily lives now. From big platform productions like God of War to addictive smartphone essentials like Farmville, there are millions of cool games to choose from. Unfortunately, I feel like it is still hard to find titles that can replicate the excitement and the amusement retro arcade games. That is why I wanted to pay homage to "the good old days" by creating an arcade style game application for my final project.  

In short, the goal of this project is to develop a text-based trivia game that allows players to test their skills and knowledge as they compete for the #1 spot on the leaderboard. 

..and you guessed it is heavily influenced by the timeless classic Street Fighter!

#Context 
Retro games were glitchy and weren't really intricate as their modern counterparts but they had an organic warmth and simplicity to them. They were usually operated by 6 buttons and a joystick, sometimes even less. Yet they were able to make thousands of kids spend numerous hours and a lot of coins just to play couple more rounds. The friendly competition they provided by allowing Player vs. Player gameplay and incorporating leaderboards made them even more addictive. 

So with Trivia Fighter; which initially started as a voice-activated Alexa skill that I tried to develop just to make my daily chores more enjoyable, I tried to replicate the retro gameplay experience. As I moved on with the project I realized that text messages would be a better medium for a game like this and migrated most of my work to a new project; Trivia Fighter Turbo, which I now plan to play to during my daily commute rather than daily chores. 

If we look at today's trivia games that can be found on each and every platform, Trivia Fighter Turbo is quite simple. It doesn't have hotlines, money prizes or crazy visual effects. It just uses the relatively small command set to present you a simple but robust gaming experience. 

#Process
The idea of the project developed after I stumbled upon a website called Open Trivia DB; a free-to-use and user-contributed trivia database. The website provided a simple API to retrieve trivia questions from the main database. So the development process started when I started playing around with their API using the infamous Ruby gem httparty. 

https://opentdb.com/api_config.php

As stated earlier, the main idea was to make Trivia Fighter a voice-activated Alexa skill. That is why the second step was to "train" the Alexa skill my coming up with necessary intents, sample utterances, and slots. Even though I ended up using Google's Dialogflow, the work I did for the Alexa skill didn't go to waste. I used all the knowledge I gained about natural language conversation interfaces from Amazon's platform, to create the architecture I have on Dialogflow. 

I constructed every module separately which helped me debug faster and create a slight MVC distinction. For example, the Dialogflow module acted as the view, while my determineResponce function acted as the controller. I achieved this by creating a distinct set of functions for different features such as session variables, accessing Trivia DB, the leaderboard database and Dialogflow. After doing that putting everything together was easy. 

I actually wanted to dig deeper into object-oriented programming in Ruby by creating custom classes that I can store questions and the state of the game in. Unfortunately, the ones I played with didn't really work out when stored as session variables and I left them in my previous Trivia Fighter project. For the Turbo version, I used a simpler approach to achieve the same effect. 

The development process took a little longer than expected but nothing some coffee can't fix. I think that I ended up with a clean and organized code that can easily support extensions and updates. One of the biggest challenges was constructing the live database but by keeping it simple as well I was able to get it working in a couple of hours. One thing I learned while developing the database is that sometimes uninstalling and reinstalling packages and gems is your only option to fix bugs. 

You can take a look at the code snippets to get an idea about how the system works.

The first code snippet starting with get "/sms/incoming" do is the main part of the code that is deployed on Heroku. When an SMS is sent to the phone number that is reserved, Twilio forwards the message to Heroku using this link. I used Dialogflow to analyze the text and determine the necessary response by implementing custom functions. 

The second code snippet shows the set of functions I created to access Open Trivia Database API. get_question(amount, cat, diff, typ) function uses httparty gem to get questions from the API using the given parameters. Other functions that are listed here are used to get information out of the JSON response provided by Open Trivia Database API. 

In the third code snippet, you can observe the function that is called when a "NEWANSWER" intent is handled. It checks certain session variables and the value of the answer provided by the user to generate the necessary response and returns it as a string. 

Lastly, you can find the full list of intents I've implemented on Dialogflow.

#Product
Final form of the project turned out to be really cool. I actually played it during my trip for the mini break!

You can start a new game, answer as much questions as you possibly can, get your name on the leaderboard and actually see how you did compared to other people. 

One thing that was added in the final stages is the time limit for answering questions. The first prototype didn't have any time limits on answering questions but the final version now checks if you answered a question under 2 minutes. If you exceed that while answering a question, you automatically lose the game. 

Given more time the question engine can be extended to ask true false questions, questions with different scores depending on their difficulty or ask questions that progressively get more difficult. 

Final Command List: New Game, Next Question, Answer is A, Repeat Question, Rules, Leaderboard, End Game, Current Score

Technologies Involved: Ruby, Sinatra, Dialogflow, Twilio, Heroku, Postgres, httparty, 

You can check the screenshots and the video to get an idea of the gameplay. 

#Reflection
First of all, I really had a lot of fun while working on this project. That is the reason I spent extra time to implement additional features like leaderboard database and timed rounds that made the project a little more market ready. 

I learnt to successfully incorporate databases to my web applications, use Google's Dialogflow API to capture user intent and how hard it is to code an Alexa skill. The trivia knowledge I gained while testing and debugging was an additional benefit. 

The current gameplay still has room for more spice and dazzle. If I had a little more time I could have experimented with adding features like GIF's, Easter Eggs, better conversational design and a more intricate question engine.

#Gameplay Demo:

![Screenshot](https://github.com/cemergin/TRIVIA-FIGHTER-TURBO/blob/master/images/1.png)

![Screenshot](https://github.com/cemergin/TRIVIA-FIGHTER-TURBO/blob/master/images/2.png)

![Screenshot](https://github.com/cemergin/TRIVIA-FIGHTER-TURBO/blob/master/images/3.png)
