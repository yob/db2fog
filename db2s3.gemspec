# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{db2s3}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Xavier Shay"]
  s.date = %q{2009-03-08}
  s.description = %q{db2s3 provides rake tasks for backing up and restoring your DB to S3}
  s.email = %q{contact@rhnh.net}
  s.files = %w(
    README
    Rakefile
    db2s3.gemspec
    init.rb
    lib
    lib/db2s3.rb
    lib/db2s3/tasks.rb
    rails
    rails/init.rb
    spec
    spec/db2s3_spec.rb
    spec/mysql_drop_schema.sql
    spec/mysql_schema.sql
    spec/s3_config.example.rb
    spec/s3_config.rb
    spec/spec_helper.rb
    tasks
    tasks/tasks.rake
  )  
  s.has_rdoc = false
  s.homepage = %q{http://github.com/xaviershay/db2s3}
  #s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  #s.rubyforge_project = %q{grit}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{db2s3 provides rake tasks for backing up and restoring your DB to S3}

  # TODO: WTF does this do
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end

  s.add_dependency(%q<aws-s3>, [">= 0.5.1"])
end
