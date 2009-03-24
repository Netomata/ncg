#!/usr/bin/ruby

require 'rubygems'
require 'mechanize'
require 'uri'
require 'ruby-debug'

$agent = WWW::Mechanize.new

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

    pathname = url.sub(/^http:\/\/[^\/]*\//,"")
    dirname, filename = File.split(pathname)
    FileUtils.mkdir_p(dirname)

    dp = DocPage.new($agent.get(url))
    File.new(pathname,"w").print(dp.export.content.sub(/<base href=.*\/>/,""))

    uri = URI.parse(url)
    dp.siblings.each { |l|
	need(uri.merge(l).to_s)
    }
end

$queue.push('http://www.netomata.com/docs/programs/ncg')
until ($queue.size == 0) do
    get($queue.pop)
end
