require 'syslog/logger'
require 'json'
require 'httparty'
require 'pp'


class StackOverflow
	include HTTParty

	format :json
	# debug_output $stdout
	base_uri = 'https://www.github.com/'

	def initialize(stackoverflow_url='https://api.stackexchange.com/2.2/')
		@base_uri = stackoverflow_url

		@options = {
			headers: {
				'Content-Type' => 'application/json',
				# 'Authorization' => "token #{token}",
			},
			# TODO Make this more secure
			verify: false
		}
	end

	def get_questions
		self.class.get("#{@base_uri}search?pagesize=50&order=desc&sort=activity&tagged=mattermost&site=stackoverflow", @options)
	end

	def format_question_output(questions_array, limit=5)
		output_array = Array.new

		output = "### Recent StackOverflow Questions\n"

		if questions_array.count > limit
			output += "*Showing #{limit} of #{questions_array.count} [more...](https://stackoverflow.com/questions/tagged/mattermost?sort=newest&pageSize=15)*\n"
		end

		count = 1
		questions_array.each do |question|
			next if count > 5

			updated_at = RelativeTime.in_words(Time.at(question['last_activity_date']))

			output += "#{count}. [#{question['title']}](#{question['link']}) - Last updated #{updated_at}\n"
			count+=1
		end

		output_array.push output + "\n---"

		output_array
	end
end