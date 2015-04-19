#!/opt/local/bin/ruby

require 'benchmark'
include Benchmark

LOOP_COUNT = 10_000

$keys = IO.readlines("benchmark_re.keys")

$pre = /[(){}!]/

def index_pre_match(k)
    return false if ! k.is_a?(String)
    return false if k.index($pre)
    return true
end

def index_re_match(k)
    return false if ! k.is_a?(String)
    return false if k.index(/[(){}!]/)
    return true
end

def index_match_rt(k)
    return false if ! k.respond_to?(:include?)
    return false if k.index("!")
    return false if k.index("(")
    return false if k.index("{")
    return true
end

def index_match_str(k)
    return false if ! k.is_a?(String)
    return false if k.index("!")
    return false if k.index("(")
    return false if k.index("{")
    return true
end

def include_match_rt(k)
    return false if ! k.respond_to?(:include?)
    return false if k.include?("!")
    return false if k.include?("(")
    return false if k.include?("{")
    return true
end

def include_match_str(k)
    return false if ! k.is_a?(String)
    return false if k.include?("!")
    return false if k.include?("(")
    return false if k.include?("{")
    return true
end

def re_match(k)
    return false if ! k.is_a?(String)
    return false if k.match(/[(){}!]/)
    return true
end

def pre_match(k)
    return false if ! k.is_a?(String)
    return false if $pre.match(k)
    return true
end

bmbm(12) do |test|

   test.report("index_pre_match") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		index_pre_match(k)
	    end
	end
   end

   test.report("index_re_match") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		index_re_match(k)
	    end
	end
   end

   test.report("index_match_rt") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		index_match_rt(k)
	    end
	end
   end

   test.report("index_match_str") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		index_match_str(k)
	    end
	end
   end

   test.report("include_match_rt") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		include_match_rt(k)
	    end
	end
   end


   test.report("include_match_str") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		include_match_str(k)
	    end
	end
   end

    test.report("re_match") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		re_match(k)
	    end
	end
    end

   test.report("pre_match") do
	LOOP_COUNT.times do |i|
	    $keys.each do |k|
		pre_match(k)
	    end
	end
   end

end
