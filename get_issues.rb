#!/usr/bin/ruby

require 'syslog/logger'
require 'yaml'
require 'pp'
require './lib/github.rb'
require './lib/mattermost.rb'
require './lib/stackoverflow.rb'
require './lib/gitlab.rb'
require 'relative_time'

$config = YAML.load(
	File.open('conf.yaml').read
)

gh = Github.new($config['github_api']['url'], 
				$config['github_api']['username'], 
				$config['github_api']['token'])

# Only issues not created by Mattermost staff

org_members = gh.get_org_members()
output_array = Array.new
# pp org_members

repos = ['mattermost/mattermost-server',
		 'mattermost/docs',
		 'mattermost/mattermost-api-reference',
		 'mattermost/mattermost-bot-sample-golang',
		 'mattermost/mattermost-load-test',
		 'mattermost/mattermost-push-proxy']

# repos = []

repos_output = Array.new


repos.each do |repo|
	# TODO: output the repo name
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
	pp filtered_issues
	
	# TODO: Remove to cover all repos
	repos_output.push({'repo' => repo_info, 'issues' => filtered_issues})
	# break
end

output_array += gh.format_repo_output(repos_output)

# These are for pull requests to the Android and iOS apps
# Only find ones >30 days
repos = [ 'mattermost/ios', 'mattermost/android']
repos_output = Array.new
# repos = []

repos.each do |repo|
	# TODO: output the repo name
	repo_info = gh.get_repo(repo)
	
	pulls = gh.get_pulls(repo)
	
	old_pulls = Array.new
	pulls.each do |pull_request|
		# Find pulls with activity older than 30 days
		# check the 'updated_at' field to see if it's been updated in the last 30 days
		# pp pull_request
		# abort

		if !org_members.include? pull_request['user']['login']
			if Time.now - Time.parse(pull_request['updated_at']) > (30 * 3600 * 24) # 30 days ago
				old_pulls.push(pull_request)
				# pp pull_request and abort
			end
		end
	end
	# TODO: Remove to cover all repos
	repos_output.push({'repo' => repo_info, 'issues' => old_pulls})
	# break
end
output_array += gh.format_repo_output(repos_output)

# Stack Overflow
so = StackOverflow.new
questions = so.get_questions
filtered_questions = Array.new
questions['items'].each do |question|
	# pp question
	if Time.now - Time.at(question['last_activity_date']) > (7 * 3600 * 24)
		filtered_questions.push(question)
	end
end

output_array += so.format_question_output(filtered_questions)

gl = Gitlab.new($config['gitlab_api']['url'], $config['gitlab_api']['token'])

gitlab_repos = ['gitlab-org/gitlab-mattermost/issues',
				'gitlab-org/omnibus-gitlab/issues?label_name=Mattermost',
				'gitlab-org/gitlab-ce/issues?label_name=mattermost']

gitlab_issues = gl.get_issues()

pp gitlab_issues
filtered_gitlab_issues = Array.new

gitlab_issues.each do |issue|
	if Time.now - Time.parse(issue['updated_at']) > (7 * 3600 * 24)
		filtered_gitlab_issues.push(issue)
	end
end

filtered_gitlab_issues.each do |issue|
	
end


# Finally, need to get these: https://gitlab.com/search?utf8=%E2%9C%93&search=mattermost&group_id=&project_id=20699&scope=issues&repository_ref=

if output_array.count > 0
	# Sends output to Mattermost
	mm = Mattermost.new($config['mattermost_api']['url'])

	# Post it to the channel
	mm_post = {
		:channel => 'town-square',
		:username => 'Alice Evans',
		:text => '### GitHub, StackOverflow & GitLab issues with activity older than 7 days:' + "\n" + output_array.join("\n")
	}

	mm.send_message(mm_post)	
end