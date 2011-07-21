Gem::Specification.new do |s|
  s.name              = "db2s3"
  s.version           = "0.4"
  s.summary           = "db2s3 provides rake tasks for backing up and restoring your DB to S3"
  s.description       = "db2s3 provides rake tasks for backing up and restoring your DB to S3"
  s.author            = "Xavier Shay"
  s.email             = ["contact@rhnh.net"]
  s.homepage          = "http://github.com/yob/db2s3"
  s.has_rdoc          = true
  s.rdoc_options      << "--title" << "DB2S3" << "--line-numbers"
  s.files             = Dir.glob("lib/**/*,rails/**/*") + ["README.rdoc", "HISTORY"]
  s.required_rubygems_version = ">=1.3.2"
  s.required_ruby_version = ">=1.8.7"

  s.add_dependency("rails", "~> 3.0")
  s.add_dependency("aws-s3", "0.6.2")

  s.add_development_dependency("rake")
  s.add_development_dependency("rspec", "~>2.6")
end
