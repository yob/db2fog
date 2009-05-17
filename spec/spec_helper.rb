require 'spec'
require 'activerecord'
require File.dirname(__FILE__) + '/../lib/db2s3'
if File.exists?(File.dirname(__FILE__) + '/s3_config.rb')
  require File.dirname(__FILE__) + '/s3_config.rb'
else
  puts "s3_config.rb does not exist - not running live tests"
end

DBConfig = {
  :adapter  => "mysql",
  :encoding => "utf8",
  :database => 'db2s3_unittest',
  :user     => "root"
}

ActiveRecord::Base.configurations = { 'production' => DBConfig }
ActiveRecord::Base.establish_connection(:production)
