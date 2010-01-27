class SpellingCorrector

	def initialize(model, editor)
		@model = model
		@editor = editor
	end

	def correct(word)
		potential_words = apply_all_edits(word)
		best_match = find_match(potential_words)
		return best_match unless best_match == nil

		second_order_edits = []
		potential_words.each do |pw|
			second_order_edits << apply_all_edits(pw)
		end

		best_match = find_match(second_order_edits.flatten)
		return best_match unless best_match == nil
		word
	end

	def find_match(potential_words)
		high_score = 0
		match = nil
		potential_words.each do |corrected_word|
			if @model[corrected_word].to_i > high_score
				match = corrected_word 
				high_score = @model[corrected_word]
			end
		end
		match
	end

	def apply_all_edits(word) 
		(@editor.delete_single_char(word) <<
		@editor.add_single_char(word) <<
		@editor.transpose_letters(word) <<
		@editor.find_one_letter_typeos(word)).flatten
	end
end

class WordEditor
	ALPHABET = "abcdefghijklmnopqrstuvwxyz"

	def delete_single_char(word) 
		([word] * word.length).
			enum_for(:each_with_index).
			collect do |x, i|
				x.delete x[i].chr
			end
	end

	def transpose_letters(word) 
		result = []
		for i in 0..word.length-2
			result << swap(word, i)
		end
		result
	end

	def swap(word, i)
		prefix = ""
		prefix = word[0..i-1] if i > 0
		prefix + word[i+1].chr + word[i].chr + word[i+2..word.length]
	end

	def find_one_letter_typeos(word)
		apply_edit_across_word_and_alphabet(word) do |new_word, alpha_letter, i|
			new_word[i] = alpha_letter unless i == word.length 
		end
	end

	def add_single_char(word)
		apply_edit_across_word_and_alphabet(word) do |new_word, alpha_letter, i|
			new_word[i..word.length-1] = alpha_letter + word[i..word.length-1]
		end
	end

	def apply_edit_across_word_and_alphabet(word)
		result = []	
		for i in 0..word.length
			ALPHABET.each_char do |alpha_letter|
				new_word = String.new(word)
				yield new_word, alpha_letter, i
				result << new_word unless new_word == word
			end
		end
		result
	end
end

class LanguageModelBuilder < Hash
	
	def build_from_filesystem(filename) 
		file = File.new(filename, "r")

		while (line = file.gets) 
			build(line)
		end

	end

	def build(str) 
		str.split(/[\s.,;"]/).each do |x|
			self[x] = self[x].to_i + 1
		end
	end

end
