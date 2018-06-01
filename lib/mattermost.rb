require 'httparty'

class Mattermost
	include HTTParty

	format :plain
	# debug_output $stdout

	def initialize(mattermost_url)
		@base_uri = mattermost_url

		@options = {
			headers: {
				'Content-Type' => 'application/json'
			},
			# TODO Make this more secure
			verify: false
		}
	end

	def send_message (payload)
		options = @options
		options[:body] = payload.to_json
		self.class.post(@base_uri, options)
	end

end