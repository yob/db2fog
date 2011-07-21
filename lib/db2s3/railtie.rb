require 'rails'

module DB2S3
  class Railtie < Rails::Railtie

    rake_tasks do
      load File.expand_path('./tasks.rb', __FILE__)
    end
  end
end
