desc "Create test database"
task :create_test_db do
  `mysqladmin -u root create db2s3_unittest`
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'db2s3'
    gemspec.summary     = "Summarize your gem"
    gemspec.description = 'db2s3 provides rake tasks for backing up and restoring your DB to S3'
    gemspec.email       = 'contact@rhnh.net'
    gemspec.homepage    = 'http://github.com/xaviershay/db2s3'
    gemspec.authors     = ['Xavier Shay']
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
