require "rubygems"
require "bundler"
Bundler.setup

require 'rspec'
require 'active_record'
require 'db2s3'

if File.exists?(File.dirname(__FILE__) + '/s3_config.rb')
  require File.dirname(__FILE__) + '/s3_config.rb'
else
  puts "s3_config.rb does not exist - exiting"
  exit 1
end

ActiveRecord::Base.configurations = { 'production' => DBConfig }
ActiveRecord::Base.establish_connection(:production)
