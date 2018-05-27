#!/usr/bin/ruby

require 'syslog/logger'
require 'yaml'
require 'pp'
require './lib/github.rb'
require 'relative_time'

$config = YAML.load(
	File.open('conf.yaml').read
)

gh = Github.new($config['github_api']['url'], 
				$config['github_api']['username'], 
				$config['github_api']['token'])

repos = ['mattermost/mattermost-server',
		 'mattermost/docs',
		 'mattermost/mattermost-api-reference',
		 'mattermost/mattermost-bot-sample-golang',
		 'mattermost/mattermost-load-test',
		 'mattermost/mattermost-push-proxy']

repos_output = Array.new

repos.each do |repo|
	# TODO: output the repo name
	repo_info = gh.get_repo(repo)
	
	issues = gh.get_issues(repo)
	# pp issues
	old_issues = Array.new
	issues.each do |issue|
		# Find issues with activity older than 7 days
		# check the 'updated_at' field to see if it's been updated in the last seven days
		# pp issue['updated_at']
		if Time.now - Time.parse(issue['updated_at']) > (7 * 3600 * 24) # seven days ago
			old_issues.push(issue)
			# pp issue and abort
		end
	end
	# TODO: Remove to cover all repos
	repos_output.push({'repo' => repo_info, 'issues' => old_issues})
	# break
end

output_array = Array.new


repos_output.each do |repo|
	output = "#{repo['repo']['name']} (#{repo['issues'].count} issues)\n"
	count = 1
	repo['issues'].each do |issue|
		updated_at = RelativeTime.in_words(Time.parse(issue['updated_at']))
		output += "#{count}. [#{issue['title']}](#{issue['html_url']}) - Last updated #{updated_at}\n"
		count+=1
	end

	output_array.push output
end

puts '**GitHub, StackOverflow & GitLab issues with activity older than 7 days:**'
puts output_array.join("\n")