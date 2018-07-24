require 'syslog/logger'
require 'json'
require 'httparty'
require 'pp'


class Github
	include HTTParty

	format :json
	# debug_output $stdout
	base_uri = 'https://www.github.com/'

	def initialize(github_url, username, token)
		@base_uri = github_url
		# @username = username
		# @password = password
		@token = token

		@options = {
			basic_auth: {
				username: username,
				password: token
			},
			headers: {
				'Content-Type' => 'application/json',
				# 'Authorization' => "token #{token}",
				'User-Agent' => 'Github-Gatherer'
			},
			# TODO Make this more secure
			verify: false
		}
	end

	def test_api
		puts self.class.get("#{@base_uri}user", @options)
	end

	def get_issues(repo)
		self.class.get("#{@base_uri}repos/#{repo}/issues", @options)
	end

	def get_pulls(repo, pull_state='open')
		self.class.get("#{@base_uri}repos/#{repo}/pulls?state=#{pull_state}", @options)
	end

	def get_repo(repo)
		self.class.get("#{@base_uri}repos/#{repo}", @options)
	end

	def get_org_members(org='mattermost')
		members = self.class.get("#{@base_uri}orgs/#{org}/members", @options)
		members_array = Array.new

		members.each do |member|
			members_array.push(member['login'])
		end

		members_array
	end


	def format_repo_output(repos_output)
		output_array = Array.new
		repos_output.each do |repo|
			next if repo['issues'].count == 0

			output = "### #{repo['repo']['name']} (#{repo['issues'].count}"

			if repo['issues'].count == 1
				output += " issue)\n"
			else
				output += " issues)\n"
			end
			
			count = 1
			repo['issues'].each do |issue|
				updated_at = RelativeTime.in_words(Time.parse(issue['updated_at']))
				output += "#{count}. [#{issue['title']}](#{issue['html_url']}) - Last updated #{updated_at}\n"
				count+=1
			end

			output_array.push output + "\n---"
		end
		
		output_array
	end
end