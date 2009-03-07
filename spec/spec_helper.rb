require 'spec'
require 'activerecord'
require File.dirname(__FILE__) + '/../lib/db2s3'
require File.dirname(__FILE__) + '/s3_config.rb'

DBConfig = {
  :adapter  => "mysql",
  :encoding => "utf8",
  :database => 'db2s3_unittest',
  :user     => "root"
}

ActiveRecord::Base.configurations = { 'production' => DBConfig }
ActiveRecord::Base.establish_connection(:production)
