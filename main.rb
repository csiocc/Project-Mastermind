require 'tty-prompt'
Debugging = false
DebuggingKi = false

class String
    def bold
        "\e[1m#{self}\e[22m" 
     end
end

module MasterMind
  module HintCalc # Module for Hintcalculation
    def self.calculate(s_code, guess_arr)
      temp_secret = s_code.dup
      temp_guess = guess_arr.dup

      actual_hint = []

      s_code.length.times do |i| # mark right pos/num
        next unless temp_guess[i] == temp_secret[i]

        actual_hint << 'X'
        temp_secret[i] = nil # delete used nums
        temp_guess[i] = nil  # delete used nums
      end

      temp_guess.each_with_index do |char, _i| # mark right num
        next unless char # skip nil/X

        secret_idx = temp_secret.index(char)
        if secret_idx
          actual_hint << 'O'
          temp_secret[secret_idx] = nil # delete used nums
        end
      end
      remaining_slots = s_code.length - actual_hint.length
      remaining_slots.times { actual_hint << '-' }
      actual_hint.sort_by do |h|
        if h == 'X'
          0
        else
          (h == 'O' ? 1 : 2)
        end
      end.join('')
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
      input = gets.chomp
      if input.downcase == 'exit'
        @code = ['exit']
      else
        @code = input.chars
        until @code.length == 4 && @code.all? { |char| char.between?('1', '6') }
          puts 'Invalid input, enter 4 Digits in a Row between 1-6'
          input = gets.chomp
          if input.downcase == 'exit'
            @code = ['exit']
            break
          else
            @code = input.chars
          end
        end
        @code
      end
    end

    def ki_get_code
      @code = Array.new(4) { rand(1..6) }.join.split('')
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

    def ki_make_guess(last_guess = nil, last_hint = nil) # Function for Ki guesscalc (This Function is inspired by https://rosettacode.org/ Python Mastermind & Gemini )
      puts "DEBUG: aktuelle mögliche Codes: #{@possible_codes.length}" if Debugging

      unless @first_guess_made
        @guess = %w[1 1 2 2] # first guess allways 1122
        @first_guess_made = true
        return @guess
      end

      if last_guess && last_hint
        @possible_codes.select! do |code|
          calculated_hint = calculate_hint(code, last_guess)
          calculated_hint == last_hint
        end
        puts "DEBUG: mögliche codes nach filterung: #{@possible_codes.length}" if DebuggingKi
      end

      if @possible_codes.length == 1
        @guess = @possible_codes.first
      else
        best_guess = nil
        max_eliminated_in_worst_case = -1

        candidate_guesses = @possible_codes

        candidate_guesses.each do |candidate_guess|
          hint_counts = Hash.new(0)
          puts "DEBUG: hint counts: #{hint_counts}" if DebuggingKi
          @possible_codes.each do |possible_secret|
            hint = calculate_hint(possible_secret, candidate_guess)
            hint_counts[hint] += 1
            puts "DEBUG: hint: #{hint}" if DebuggingKi
          end

          worst_case_size = hint_counts.values.max || 0
          puts "DEBUG: worst case size: #{worst_case_size}" if DebuggingKi

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
      input = gets.chomp
      if input.downcase == 'exit'
        @guess = ['exit']
      elsif input.downcase == 'help'
        @guess = ['help']
      else
        @guess = input.chars
        until @guess.length == 4 && @guess.all? { |char| char.between?('1', '6') }
          puts 'Invalid input, enter 4 Digits in a Row between 1-6'
          input = gets.chomp
          if input.downcase == 'exit'
            @guess = ['exit']
            break
          elsif input.downcase == 'help'
            @guess = ['help']
            break
          else
            @guess = input.chars
          end
        end
        @guess
      end
    end
  end

  def self.still_no_win?(setter_one, guess)
    return true if setter_one.display_hint(guess) != 'XXXX'

    false if setter_one.display_hint(guess) == 'XXXX'
  end

  def self.avg_tries(round_count, tries_sum)
    return 0.0 if round_count == 0

    tries_sum.to_f / round_count
  end

  def self.play_game
    total_rounds_played = 0
    total_tries_sum = 0

    loop do # Main Game Loop
      prompt = TTY::Prompt.new # chose role
      player_choice_input = prompt.select('Choose your Role') do |menu|
        menu.choice 'Set-Code'
        menu.choice 'Guess-Code'
      end

      puts "DEBUG: player_choice_input ist jetz: #{player_choice_input}" if Debugging
      puts "DEBUG: Typ von player_choice_input: #{player_choice_input.class}" if Debugging
      case player_choice_input # set role
      when 'Set-Code'
        setter_one = Setter.new([], true)
        guesser_one = Guesser.new([], false)
        puts "DEBUG: Player is Setter #{setter_one.player_role}" if Debugging
      when 'Guess-Code'
        setter_one = Setter.new([], false)
        guesser_one = Guesser.new([], true)
        puts "DEBUG: Player is Guesser #{guesser_one.player_role}" if Debugging
      end


      if setter_one.player_role
        exit_code = setter_one.get_code
        if exit_code.join.downcase == 'exit'
          puts 'Exiting, cu!'
          return
        end
      else # Ki is setter
        setter_one.ki_get_code
        puts "Ki generated a Code, try to crack it!".bold
      end

      total_rounds_played += 1
      current_round_tries = 0

      puts "Round: #{total_rounds_played} | AVG Tries: #{MasterMind.avg_tries(total_rounds_played - 1,
                                                                              total_tries_sum).round(1)}"
      puts "Insert your Guess a Number between 1111 - 6666 |" + " help ".bold + "for Hint help or" + " exit ".bold + "to leave" if guesser_one.player_role
      puts 'Calculating......' if setter_one.player_role

      max_tries = 12
      last_ki_guess = nil # storage for ki guess
      last_ki_hint = nil # storage for ki hint

      loop do # Round Game Loop
        if current_round_tries >= max_tries # game stops after 12 trys
          puts "Game over! The code was #{setter_one.code.join}"
          total_tries_sum += (current_round_tries + 1)
          break
        end

        if guesser_one.player_role
          guesser_one.make_guess
          guess = guesser_one.guess.to_a
        else # Ki is guesser
          guess = guesser_one.ki_make_guess(last_ki_guess, last_ki_hint)
          last_ki_guess = guess # stores ki guess
          puts "KI-Guess: #{guess.join}"
        end

        hint = setter_one.display_hint(guess)
        last_ki_hint = hint
        if guess.join.downcase == 'help'
          puts "Hint Help: 'X' = right Num/Pos | 'O' = right num"
          guesser_one.make_guess
        end
        if guess.join.downcase == 'exit'
          puts 'Exiting, cu!'
          return # stop game exit
        end

        p guess
        p setter_one.display_hint(guess)
        p "actual code: #{setter_one.code.join}" if Debugging

        unless still_no_win?(setter_one, guess)
          if setter_one.player_role && current_round_tries + 1 > 4 && current_round_tries + 1 > 8
            puts "Ki - got it in #{current_round_tries + 1} Trys! This Ki is so bad, or your Code is insane."
          end
          if setter_one.player_role && current_round_tries + 1 > 4 && current_round_tries + 1 < 8
            puts "Ki - got it in #{current_round_tries + 1} Trys! Still good."
          end
          if setter_one.player_role && current_round_tries + 1 <= 4
            puts "Ki - got it in #{current_round_tries + 1} Trys Awesome not? Your Code is probably a bit too easy."
          end
          if guesser_one.player_role && current_round_tries + 1 > 4 && current_round_tries + 1 > 8
            puts "Ki - got it in #{current_round_tries + 1} Trys! This was bad."
          end
          if guesser_one.player_role && current_round_tries + 1 > 4 && current_round_tries + 1 < 8
            puts "Ki - got it in #{current_round_tries + 1} Trys! Still good."
          end
          if guesser_one.player_role && current_round_tries + 1 <= 4
            puts "GZ! u got it in #{current_round_tries + 1} Trys Awesome! Your're a crack.'"
          end
        end

        if MasterMind.still_no_win?(setter_one, guess)
          current_round_tries += 1
        else
          puts "GZ! U got it in #{current_round_tries + 1} Trys" if guesser_one.player_role
          total_tries_sum += (current_round_tries + 1)
          break # Stop gamecycle player win
        end
      end
      prompt = TTY::Prompt.new
      play_again = prompt.yes?('Play another round?')
      break unless play_again
    end
    puts "Final Average Tries over #{total_rounds_played} rounds: #{MasterMind.avg_tries(total_rounds_played,
                                                                                         total_tries_sum).round(1)}"
  end
end

MasterMind.play_game
