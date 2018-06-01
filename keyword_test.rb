#!/usr/bin/ruby

require 'syslog/logger'
require 'yaml'
require 'pp'
require './lib/github.rb'
require 'relative_time'
require 'highscore'

$config = YAML.load(
	File.open('conf.yaml').read
)

gh = Github.new($config['github_api']['url'], 
				$config['github_api']['username'], 
				$config['github_api']['token'])

issues = gh.get_issues('mattermost/docs')

issues.each do |issue|
	text = Highscore::Content.new issue['body']

	text.keywords.top(10).each do |keyword|
	  puts "#{keyword.text} - #{keyword.weight}"   # => keyword text
	  keyword.weight # => rank weight (float)
	  # abort
	end
end