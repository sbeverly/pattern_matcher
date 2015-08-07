require 'benchmark'

class PatternMatcher
	def initialize(file)
		@file_path = file
		@pattern_hash = Hash.new
		@first_path_row = nil

		build_main_hash
		sort_hash
	end


	public


	def find_matches
		counter = 0
		IO.foreach(@file_path) do |path|
			if counter > @first_path_row
				pattern = get_best_pattern(path.chomp)
				pattern ? puts("#{pattern}") : puts("NO MATCH")
			end
			counter += 1
		end
	end

	def get_best_pattern(path)
		path_array = path.split("/")
		path_array.shift if path_array.first == ""
		path_array.pop if path_array.last == ""
		element_count = path_array.length
		
		possible_matches = @pattern_hash[element_count]

		if possible_matches
			possible_matches.find { |pattern| is_match(path_array, pattern) }
		else
			return false
		end
	end


	private

	def is_match(path_array, pattern)
		pattern = pattern.split(",")
		path_array.each_with_index do |chr, index|
			next if pattern[index] == "*"
			next if chr == pattern[index]
			return false
		end

		return true
	end

	def build_main_hash
		counter = 0
		no_of_patterns = nil

		IO.foreach(@file_path) do |line|
			no_of_patterns = line.to_i if counter == 0
			break if counter == no_of_patterns + 1
	
			add_pattern_to_hash(line.chomp)
			counter += 1
		end

		@first_path_row = no_of_patterns + 1
	end

	def add_pattern_to_hash(pattern)
		no_of_elements = pattern.split(",").length
		if @pattern_hash[no_of_elements].is_a? Array 
			@pattern_hash[no_of_elements] << pattern
		else
			@pattern_hash[no_of_elements] = [pattern]
		end
	end

	def sort_hash
		@pattern_hash.each do |key, value|
			next if key == 1

			no_wildcards = []
			single_asterik_order = []
			multiple_asterik_order = []

			value.each do |pattern|
				no_of_asteriks = count_asteriks(pattern)

				if no_of_asteriks == 1
					single_asterik_order << pattern
				elsif no_of_asteriks > 1
					multiple_asterik_order << pattern
				else
					no_wildcards << pattern
				end
			end
			
			single_asterik_order = single_asterik_order.sort_by { |pattern| pattern.index("*") }
			multiple_asterik_order = resolve_multiple_wildcard_order(multiple_asterik_order)
			
			@pattern_hash[key] = no_wildcards.concat(single_asterik_order).concat(multiple_asterik_order)
		end
	end

	def resolve_multiple_wildcard_order(array)
		hash = Hash.new

		array.each do |pattern|
			no_of_asteriks = count_asteriks(pattern)
			
			if hash[no_of_asteriks].is_a? Array
				hash[no_of_asteriks] << pattern
			else
				hash[no_of_asteriks] = [pattern]
			end
		end

		array = []

		hash.keys.sort.each do |key|
			hash[key].sort! { |a,b| ((a.index("*") <=> b.index("*")) == 0) ? (a.index("*") <=> b.index("*")) : (asterik_index_sum(a) <=> asterik_index_sum(b)) }
			array += hash[key]
		end

		array
	end

	def asterik_index_sum(pattern)
		pattern = pattern.split(",")
		sum = 0
		pattern.each_with_index { |chr, index| sum += index if chr == "*" }
		sum
	end

	def count_asteriks(pattern)
		pattern = pattern.split(",")
		count = 0
		pattern.each { |character| count += 1 if character == "*" }
		count
	end
end

PatternMatcher.new(ARGV[0]).find_matches