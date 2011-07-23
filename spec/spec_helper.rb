require "rubygems"
require "bundler"
Bundler.setup

require 'rspec'
require 'fileutils'
require 'timecop'
require 'active_record'
require 'db2fog'

if File.exists?(File.dirname(__FILE__) + '/db_config.rb')
  require File.dirname(__FILE__) + '/db_config.rb'
else
  puts "db_config.rb does not exist - exiting"
  exit 1
end

DB2Fog.config = {
  :provider   => 'Local',
  :local_root => File.dirname(__FILE__) + "/storage",
  :directory  => 'db2fog-test'
}

ActiveRecord::Base.configurations = { 'production' => DBConfig }
ActiveRecord::Base.establish_connection(:production)
