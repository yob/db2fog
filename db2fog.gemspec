Gem::Specification.new do |s|
  s.name              = "db2fog"
  s.version           = "0.7.0"
  s.summary           = "db2fog provides rake tasks for backing up and restoring your DB to cloud storage providers"
  s.description       = "db2fog provides rake tasks for backing up and restoring your DB to cloud storage providers"
  s.author            = "James Healy"
  s.email             = ["james@yob.id.au"]
  s.homepage          = "http://github.com/yob/db2fog"
  s.has_rdoc          = true
  s.rdoc_options      << "--title" << "DB2Fog" << "--line-numbers"
  s.files             = Dir.glob("lib/**/*") + ["README.rdoc", "HISTORY"]
  s.required_rubygems_version = ">=1.3.2"
  s.required_ruby_version = ">=1.8.7"

  s.add_dependency("rails", "~> 4.0")
  s.add_dependency("activerecord", "~> 4.0")
  s.add_dependency("fog", "~> 1.0")

  s.add_development_dependency("rake")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("rspec", "~>2.6")
  s.add_development_dependency("timecop", "~>0.3.5")
end
