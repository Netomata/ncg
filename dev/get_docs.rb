#!/usr/bin/ruby

require 'rubygems'
require 'mechanize'
require 'uri'
require 'ruby-debug'

require 'optparse'
$release = ""
OptionParser.new do |opts|
    opts.banner = "Usage: get_docs.rb [-r RELEASE]"

    opts.on("-r",
	    "--release RELEASE",
	    "Obtain docs for specified release") do |r|
	$release = r
    end

    opts.on_tail("-h", "--help", "Show this message") do
	puts opts
	exit
    end
end.parse!

if ($release.empty?) then
    $first_url = "http://www.netomata.com/docs/programs/ncg"
else
    $first_url = "http://www.netomata.com/docs-#{$release}/programs/ncg"
end

$agent = Mechanize.new

class DocPage
   def siblings
       if (@siblings.nil?) then
	   @siblings = self.export.links_with(:href => /^\.\.\//).collect {|l| l.href }.uniq.reject{ |m| m.match(/#/) }
       end
       @siblings
   end

   def export
	$agent.click @page.links.find { |l|
	    l.text == 'Printer-friendly version'
	}
   end

   def initialize(page)
       @page = page
   end

   def method_missing(sym, *args)
       @page.send(sym, *args)
   end
end

$queue = []
$got = []

def need(url)
    if (!$got.include?(url)) then
	$queue.push(url)
    end
end

def get(url)
    print "Request for #{url}..."
    if ($got.include?(url)) then
	print "Already have it.\n"
    else
	print "Getting it.\n"
    end
    $got.push(url)	# push early, in case page refers to itself

    pathname = url.sub(/^http:\/\/[^\/]*\/[^\/]*\//,"doc/")
    pathname.concat(".html") unless (pathname =~ /\.html$/)
    dirname, filename = File.split(pathname)
    FileUtils.mkdir_p(dirname)

    dp = DocPage.new($agent.get(url))
    File.new(pathname,"w").print(
	dp.export.content.
	    sub(/<base href=.*\/>/,"").
	    gsub(/(href="\.\.\/[^"]*)"/, '\1.html"')
    )

    uri = URI.parse(url)
    dp.siblings.each { |l|
	need(uri.merge(l).to_s)
    }
end

$queue.push($first_url)
until ($queue.size == 0) do
    get($queue.pop)
end
