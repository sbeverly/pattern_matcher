require 'benchmark'

class PatternMatcher
	def initialize(file)
		@file_path = file
		@pattern_hash = Hash.new

		build_main_hash
		sort_hash
	end



	public


	def find_matches
	end



	private


	def build_main_hash
		counter = 0
		no_of_patterns = nil

		IO.foreach(@file_path) do |line|
			no_of_patterns = line.to_i if counter == 0
			break if counter == no_of_patterns + 1
	
			add_pattern_to_hash(line.chomp)
			counter += 1
		end
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
		puts @pattern_hash
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

puts Benchmark.measure { PatternMatcher.new(ARGV[0]).find_matches }