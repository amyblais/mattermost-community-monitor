#!/usr/bin/ruby

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


mm.send_direct_message('bobsmith', 'Hello Bob')