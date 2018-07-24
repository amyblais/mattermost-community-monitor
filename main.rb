#!/usr/bin/env ruby

require 'syslog/logger'
require 'yaml'
require 'pp'
require './lib/github.rb'
require './lib/mattermost_api.rb'
require './lib/stackoverflow.rb'
require './lib/gitlab.rb'
require 'relative_time'

$config = YAML.load(
	File.open('conf.yaml').read
)

mm = MattermostApi.new($config['mattermost_api']['url'],
					   $config['mattermost_api']['username'],
					   $config['mattermost_api']['password'])

gh = Github.new($config['github_api']['url'], 
				$config['github_api']['username'], 
				$config['github_api']['token'])

mattermost_recipient = $config['mattermost_api']['recipient']

# Only issues not created by Mattermost staff
org_members = gh.get_org_members()

# Main Github Repositories
output_array = Array.new

repos = ['mattermost/mattermost-server',
		 'mattermost/docs',
		 'mattermost/mattermost-api-reference',
		 'mattermost/mattermost-bot-sample-golang',
		 'mattermost/mattermost-load-test',
		 'mattermost/mattermost-push-proxy']

repos_output = Array.new

repos.each do |repo|
	repo_info = gh.get_repo(repo)
	
	issues = gh.get_issues(repo)

	filtered_issues = Array.new
	issues.each do |issue|
		if !org_members.include? issue['user']['login']
			if Time.now - Time.parse(issue['updated_at']) > (7 * 3600 * 24)
				filtered_issues.push(issue)
			end
		end
	end
	repos_output.push({'repo' => repo_info, 'issues' => filtered_issues})
end

output_array = gh.format_repo_output(repos_output)

output_array.each do |message|
	mm.send_direct_message(mattermost_recipient, message)
end

# These are for pull requests to the Android and iOS apps
# Only find ones >30 days
repos = [ 'mattermost/ios', 'mattermost/android']
repos_output = Array.new

repos.each do |repo|
	repo_info = gh.get_repo(repo)
	
	pulls = gh.get_pulls(repo)
	
	old_pulls = Array.new
	pulls.each do |pull_request|
		# Find pulls with activity older than 30 days
		# check the 'updated_at' field to see if it's been updated in the last 30 days
		if !org_members.include? pull_request['user']['login']
			if Time.now - Time.parse(pull_request['updated_at']) > (30 * 3600 * 24) # 30 days ago
				old_pulls.push(pull_request)
				# pp pull_request and abort
			end
		end
	end
	repos_output.push({'repo' => repo_info, 'issues' => old_pulls})
end
output_array = gh.format_repo_output(repos_output)
# mm.send_direct_message(mattermost_recipient, output_array.join("\n"))

# Stack Overflow
so = StackOverflow.new
questions = so.get_questions
filtered_questions = Array.new
questions['items'].each do |question|
	if Time.now - Time.at(question['last_activity_date']) > (7 * 3600 * 24)
		filtered_questions.push(question)
	end
end

output_array = so.format_question_output(filtered_questions)
output_array.each do |message|
	mm.send_direct_message(mattermost_recipient, message)
end

# Gitlab
gl = Gitlab.new($config['gitlab_api']['url'], $config['gitlab_api']['token'])

gitlab_repos = ['gitlab-org/omnibus-gitlab?labels=Mattermost',
				'gitlab-org/gitlab-mattermost',
				'gitlab-org/gitlab-ce?labels=mattermost']

gitlab_repos.each do |repo|
	gitlab_repos_output = Array.new
	
	repo_info = nil
	issues = gl.get_issues(repo)

	filtered_issues = Array.new
	issues.each do |issue|
		# Because Gitlab makes you get the project info from the ID
		if repo_info.nil?
			repo_info = gl.get_repo(issue['project_id'])
		end

		if Time.now - Time.parse(issue['updated_at']) > (7 * 3600 * 24)
			filtered_issues.push(issue)
		end
	end

	gitlab_repos_output.push({'repo' => repo_info, 'issues' => filtered_issues})
	output_array = gl.format_repo_output(gitlab_repos_output)
	mm.send_direct_message(mattermost_recipient, output_array.join("\n"))
end

# Low Traffic Repos
# Only show issues updated in the last week, otherwise hide them
repos = ['mattermost/mattermost-redux',
		 'mattermost/mattermost-developer-documentation',
		 'mattermost/mattermost-integration-gitlab',
		 'mattermost/mattermost-integration-giphy',
		 'mattermost/mattermost-heroku',
		 'mattermost/mattermost-interactive-post-demo',
		 'mattermost/mattermost-developer-kit',
		 'mattermost/mattermost-webrtc',
		 'mattermost/mattermost-build',
		 'mattermost/mattermost-plugin-profanity-filter',
		 'mattermost/mattermost-plugin-memes',
		 'mattermost/mattermost-plugin-autolink']

repos_output = Array.new

repos.each do |repo|
	repo_info = gh.get_repo(repo)
	issues = gh.get_issues(repo)

	filtered_issues = Array.new
	issues.each do |issue|
		begin
			if issue['user'].nil? || issue['user']['login'].nil?
				next
			end
			
			if !org_members.include? issue['user']['login']
				# Only check for ones that have activity in the last week
				if Time.now - Time.parse(issue['updated_at']) < (7 * 3600 * 24)
					filtered_issues.push(issue)
				end
			end
		rescue Exception => e
			pp e
		end
	end
	repos_output.push({'repo' => repo_info, 'issues' => filtered_issues})
end

output_array = gh.format_repo_output(repos_output)

output_array.each do |message|
	mm.send_direct_message(mattermost_recipient, message)
end