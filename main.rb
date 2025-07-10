require "tty-prompt"
Debugging = false

module MasterMind
  
  class Setter
    attr_reader :code, :hint
    def initialize(code)
      @code = code
      @hint = []
    end

    def get_code
      puts "Insert your Code a Number between 1111 - 6666"
      @code = gets.chomp.chars.to_a
    end
    
    def ki_get_code
      @code = Array.new(4) { rand(1..6) }.join.split("")
    end

    def display_hint(guess)
      self.compare(guess)
      @hint
    
    end

    def compare(guess)
      temp_code = @code.dup
      temp_guess = guess.dup
      hint = Array.new(@code.length, "")

      @code.length.times do |i| #check for num&pos match
        if temp_guess [i] == temp_code[i]
          hint[i] = "X"
          temp_code[i] = nil #delete used num
          temp_guess[i] = nil
        end
      end

      temp_guess.each_with_index do |char, i| #check remaining chars for num match
        next unless char #skip removed chars
        code_i = temp_code.index(char)
        if code_i
          hint[i] = "O"
          temp_code[code_i] = nil #delete used num
        else
          hint[i] = "-" #mark - if not O / X
        end
      end

      hint.each_with_index do |value, i|
        if value.empty? #nil's replaced by "-" 
          hint[i]
        end
      end

      @hint = hint.join("")
    end
    
  end
  

  class Guesser 
    attr_reader :guess
    def initialize(guess)
      @guess = guess
    end

    def make_guess 
      
      @guess = gets.chomp.chars.to_a
    end
  end

  def self.still_no_win?(setter_one, guess)
    return true if setter_one.display_hint(guess) != "XXXX"
    return false if setter_one.display_hint(guess) == "XXXX"
  end

  def self.avg_tries(round_count, tries_sum) 
    return 0.0 if round_count == 0
    tries_sum.to_f / round_count
  end

  def self.play_game
    total_rounds_played = 0
    total_tries_sum = 0

    loop do  #Main Game Loop
      setter_one = Setter.new([])
      guesser_one = Guesser.new([])
      setter_one.ki_get_code

      total_rounds_played += 1
      current_round_tries = 0

      puts "Round: #{total_rounds_played} | AVG Tries: #{MasterMind.avg_tries(total_rounds_played - 1, total_tries_sum).round(1)}"
      puts "Insert your Guess a Number between 1111 - 6666 or 'exit' to leave"

      max_tries = 12
      loop do # Round Game Loop

        if current_round_tries >= max_tries # game stops after 12 trys
          puts "Game over! The code was #{setter_one.code.join}"
          break
        end

        guesser_one.make_guess
        guess = guesser_one.guess.to_a

        if guess.join.downcase == "exit"
          puts "Exiting, cu!"
          return #stop game exit
        end

        p guess
        p setter_one.display_hint(guess)
        p "actual code: #{setter_one.code.join}" if Debugging

        if MasterMind.still_no_win?(setter_one, guess)
          current_round_tries += 1
        else
          puts "GZ! U got it in #{current_round_tries} Trys"
          total_tries_sum += (current_round_tries + 1)
          break #Stop gamecycle player win
        end
      end
      prompt = TTY::Prompt.new
      play_again = prompt.yes?("Play another round?")
      break unless play_again
    end
    puts "Final Average Tries over #{total_rounds_played} rounds: #{MasterMind.avg_tries(total_rounds_played, total_tries_sum).round(1)}"
  end
     
end

MasterMind.play_game