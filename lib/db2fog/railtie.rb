require 'rails'
require 'db2fog'

class DB2Fog
  class Railtie < Rails::Railtie

    rake_tasks do
      load File.expand_path('tasks.rb', File.dirname(__FILE__))
    end
  end
end
