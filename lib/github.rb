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

	def get_repo(repo)
		self.class.get("#{@base_uri}repos/#{repo}")
	end

end