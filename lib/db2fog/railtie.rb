require 'rails'
require 'db2fog'

class DB2Fog
  class Railtie < Rails::Railtie

    rake_tasks do
      load File.expand_path('./tasks.rb', __FILE__)
    end
  end
end
