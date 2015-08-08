require 'benchmark'

=begin

This class is designed to pull in all possible patterns into memory and sort them by the 'best possible match' rules.  Finding a matching pattern is done
by looking up the number of fields in a path and matching it to a key in the pattern_hash to narrow down possible matches.
	
=end

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
				pattern ? puts(pattern) : puts("NO MATCH")
			end
			counter += 1
		end
	end

	# look up array of possible matches by fields length, then find the first match, which will be the best one.
	def get_best_pattern(path)
		path_array = path.split("/")
		path_array.shift if path_array.first == ""
		path_array.pop if path_array.last == ""
		no_of_fields = path_array.length
		
		possible_matches = @pattern_hash[no_of_fields]

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

		# only read patterns from input file
		IO.foreach(@file_path) do |line|
			no_of_patterns = line.to_i if counter == 0
			break if counter == no_of_patterns + 1
	
			add_pattern_to_hash(line.chomp)
			counter += 1
		end

		# set starting point for the paths section of the input file
		@first_path_row = no_of_patterns + 1
	end

	# add pattern into hash based on number of fields
	def add_pattern_to_hash(pattern)
		no_of_fields = pattern.split(",").length
		if @pattern_hash[no_of_fields].is_a? Array 
			@pattern_hash[no_of_fields] << pattern
		else
			@pattern_hash[no_of_fields] = [pattern]
		end
	end

	# sort each array in pattern hash so that the first match is the best one.
	def sort_hash
		@pattern_hash.each do |key, value|
			next if key == 1

			no_wildcards_order = []
			single_asterik_order = []
			multiple_asterik_order = []

			value.each do |pattern|
				no_of_wildcards = count_asteriks(pattern)

				if no_of_wildcards == 1
					single_asterik_order << pattern
				elsif no_of_wildcards > 1
					multiple_asterik_order << pattern
				else
					no_wildcards_order << pattern
				end
			end
			
			single_asterik_order = single_asterik_order.sort_by { |pattern| pattern.index("*") }
			multiple_asterik_order = resolve_multiple_wildcard_order(multiple_asterik_order)
			
			@pattern_hash[key] = no_wildcards_order.concat(single_asterik_order).concat(multiple_asterik_order)
		end
	end

	# separate patterns with multiple wildcards into groups based on number of wildcards so that they can be compared to eachother and ordered.
	def resolve_multiple_wildcard_order(multiple_wildcard_array)
		hash = Hash.new
		multiple_wildcard_array.each do |pattern|
			no_of_wildcards = count_asteriks(pattern)
			
			if hash[no_of_wildcards].is_a? Array
				hash[no_of_wildcards] << pattern
			else
				hash[no_of_wildcards] = [pattern]
			end
		end

		multiple_wildcard_array = []
		hash.keys.sort.each do |key|
			# Attempts to sort by the position of the the leftomost wildcard, if two patterns have leftmost wildcards in the same position,
			# it will sort using the sum of the indexes of the wildcards - this will select the pattern with the rightmost wildcard as the tiebreaker requires.

			hash[key].sort! { |a,b| ((a.index("*") <=> b.index("*")) == 0) ? (a.index("*") <=> b.index("*")) : (asterik_index_sum(a) <=> asterik_index_sum(b)) }
			multiple_wildcard_array += hash[key]
		end

		multiple_wildcard_array
	end

	# using the sum of the indexes to determine which pattern has the right most wildcards (works because I am comparing against patterns with same number of wildcards)
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