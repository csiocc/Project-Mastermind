require "tty-prompt"
Debugging = false


module MasterMind #Module für Ki Hinweisberechnung (Inspired by  https://rosettacode.org/ Python Mastermind & Gemini )

  module HintCalc #Module for Hintcalculation
    def self.calculate(s_code, guess_arr)
      temp_secret = s_code.dup
      temp_guess = guess_arr.dup

      provisional_hints = []

      s_code.length.times do |i|  #mark right pos/num
        if temp_guess[i] == temp_secret[i]
          provisional_hints << "X"
          temp_secret[i] = nil # delete used nums
          temp_guess[i] = nil  # delete used nums
        end
      end

      temp_guess.each_with_index do |char, i|
        next unless char # skip nil/X
          secret_idx = temp_secret.index(char)
        if secret_idx
          provisional_hints << "O"
          temp_secret[secret_idx] = nil # delete used nums
        end
      end
      remaining_slots = s_code.length - provisional_hints.length
      remaining_slots.times { provisional_hints << "-" }
      provisional_hints.sort_by { |h| h == "X" ? 0 : (h == "O" ? 1 : 2) }.join("")
    end
  end

  class Setter
    attr_reader :code, :hint
    attr_accessor :player_role
    def initialize(code, player_role)
      @code = code
      @hint = []
      @player_role = player_role
    end

    def get_code
      puts "Insert your Code a Number between 1111 - 6666"
      @code = gets.chomp.chars.to_a
    end
    
    def ki_get_code
      @code = Array.new(4) { rand(1..6) }.join.split("")
    end

    def display_hint(guess)
      @hint = HintCalc.calculate(@code, guess)
      @hint
    end  
  end
  

  class Guesser 
    attr_reader :guess, :player_role
    attr_accessor :possible_codes

    def initialize(guess, player_role)
      @guess = guess
      @player_role = player_role
      @possible_codes = generate_codes
      @first_guess_made = false
    end

    def generate_codes
      codes = []
      (1..6).each do |a|
        (1..6).each do |b|
          (1..6).each do |c|
            (1..6).each do |d|
              codes << [a.to_s, b.to_s, c.to_s, d.to_s]
            end
          end
        end
      end
      codes
    end

    def calculate_hint(s_code, guess_arr)
      HintCalc.calculate(s_code, guess_arr)
    end

    def ki_make_guess(last_guess = nil, last_hint = nil)
      puts "DEBUG: aktuelle mögliche Codes: #{@possible_codes.length}" if Debugging

      unless @first_guess_made
        @guess = ["1", "1", "2", "2"] #first guess allways 1122
        @first_guess_made = true
        return @guess
      end

      if last_guess && last_hint
        @possible_codes.select! do |code|
          calculated_hint = calculate_hint(code, last_guess)
          calculated_hint == last_hint
        end
        puts "DEBUG: mögliche codes nach filterung: #{@possible_codes.length}" if Debugging
      end

      if @possible_codes.length == 1
        @guess = @possible_codes.first
      else
        best_guess = nil
        max_eliminated_in_worst_case = -1

        candidate_guesses = @possible_codes

        candidate_guesses.each do |candidate_guess|
          hint_counts = Hash.new(0)

          @possible_codes.each do |possible_secret|
            hint = calculate_hint(possible_secret, candidate_guess) 
            hint_counts[hint] += 1
          end

          worst_case_size = hint_counts.values.max || 0 

          if best_guess.nil? || worst_case_size < max_eliminated_in_worst_case
            max_eliminated_in_worst_case = worst_case_size
            best_guess = candidate_guess
          end
        end
        @guess = best_guess
      end
      
      @guess
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
      prompt = TTY::Prompt.new #chose role
      player_choice_input = prompt.select("Choose your Role") do |menu|
        menu.choice "Set-Code"
        menu.choice "Guess-Code"
      end

      puts "DEBUG: player_choice_input ist jetz: #{player_choice_input}" if Debugging
      puts "DEBUG: Typ von player_choice_input: #{player_choice_input.class}" if Debugging
      case player_choice_input #set role
        when "Set-Code"
          setter_one = Setter.new([], true)
          guesser_one = Guesser.new([], false)
          puts "DEBUG: Player is Setter #{setter_one.player_role}" if Debugging
        when "Guess-Code"
          setter_one = Setter.new([], false)
          guesser_one = Guesser.new([], true)
          puts "DEBUG: Player is Guesser #{guesser_one.player_role}" if Debugging
      end

      if setter_one.player_role 
        setter_one.get_code
      else #Ki is setter
        setter_one.ki_get_code
      end
     

      total_rounds_played += 1
      current_round_tries = 0

      puts "Round: #{total_rounds_played} | AVG Tries: #{MasterMind.avg_tries(total_rounds_played - 1, total_tries_sum).round(1)}"
      puts "Insert your Guess a Number between 1111 - 6666 or 'exit' to leave" if guesser_one.player_role
      puts "Calculating......" if setter_one.player_role

      max_tries = 12
      last_ki_guess = nil #storage for ki guess
      last_ki_hint = nil #storage for ki hint

      loop do # Round Game Loop

        if current_round_tries >= max_tries # game stops after 12 trys
          puts "Game over! The code was #{setter_one.code.join}"
          total_tries_sum += (current_round_tries + 1)
          break
        end

        if guesser_one.player_role
          guesser_one.make_guess
          guess = guesser_one.guess.to_a
        else #Ki is guesser
          guesser_one.ki_make_guess(last_ki_guess, last_ki_hint)
          guess = guesser_one.ki_make_guess
          last_ki_guess = guess #stores ki guess
          puts "KI-Guess: #{guess.join}"
        end

        hint = setter_one.display_hint(guess)
        last_ki_hint = hint

        if guess.join.downcase == "exit"
          puts "Exiting, cu!"
          return #stop game exit
        end

        p guess
        p setter_one.display_hint(guess)
        p "actual code: #{setter_one.code.join}" if Debugging

        unless still_no_win?(setter_one, guess)
          puts "Ki - got it in #{current_round_tries+1} Trys! This Ki is so bad, or your Code is insane." if setter_one.player_role && current_round_tries+1 > 4 && current_round_tries+1 > 8
          puts "Ki - got it in #{current_round_tries+1} Trys! Still good." if setter_one.player_role && current_round_tries+1 > 4 && current_round_tries+1 < 8
          puts "Ki - got it in #{current_round_tries+1} Trys Awesome not? Your Code is a bit too easy." if setter_one.player_role && current_round_tries+1 <= 4
          puts "Ki - got it in #{current_round_tries+1} Trys! This was bad." if guesser_one.player_role && current_round_tries+1 > 4 && current_round_tries+1 > 8
          puts "Ki - got it in #{current_round_tries+1} Trys! Still good." if guesser_one.player_role && current_round_tries+1 > 4 && current_round_tries+1 < 8
          puts "GZ! u got it in #{current_round_tries+1} Trys Awesome! Your're a crack.'" if guesser_one.player_role && current_round_tries+1 <= 4
        end

        if MasterMind.still_no_win?(setter_one, guess)
          current_round_tries += 1
        else
          puts "GZ! U got it in #{current_round_tries+1} Trys" if guesser_one.player_role
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