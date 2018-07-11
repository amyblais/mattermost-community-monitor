require 'syslog/logger'
require 'json'
require 'httparty'
require 'pp'
require 'cgi'


class Gitlab
	include HTTParty

	format :json
	# debug_output $stdout
	base_uri = 'https://gitlab.com/api/v4/'



	def initialize(gitlab_url='https://gitlab.com/api/v4/', token)
		@base_uri = gitlab_url
		@token = token 

		@options = {
			headers: {
				'Content-Type' => 'application/json',
				'PRIVATE-TOKEN' => "#{token}"
			},
			# TODO Make this more secure
			verify: false
		}
	end

	def test_api
		puts self.class.get("#{@base_uri}user", @options)
	end

	def get_issues(repo='gitlab-org/gitlab-mattermost')
		url_params = ''
		if repo.include? '?'
			repo, url_params = repo.split('?')
		end


		project_id = CGI.escape(repo)

		before = (Time.now - (86400 * 7)).strftime('%Y-%m-%d')

		if !url_params.nil?
			before += "&#{url_params}"
		end

		self.class.get("#{@base_uri}/projects/#{project_id}/issues?state=opened&updated_before=#{before}", @options)
	end

	def get_repo(repo)
		self.class.get("#{@base_uri}projects/#{repo}")
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

# gl = Gitlab.new()

# pp gl.get_issues