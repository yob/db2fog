# coding: utf-8

namespace :db2fog do
  desc "Save a full back to S3"
  task :backup => :environment do
    DB2Fog.new.backup
  end

  desc "Restore your DB from S3"
  task :restore => :environment do
    DB2Fog.new.restore
  end

  desc "Keep all backups for the last day, one per day for the last week, and one per week before that. Delete the rest."
  task :clean => :environment do
    DB2Fog.new.clean
  end

  namespace :backup do
    task :full => :environment do
      $stderr.puts "the db2fog:backup:full rake task is deprecated, use db2fog:backup instead"
      DB2Fog.new.backup
    end

    task :restore => :environment do
      $stderr.puts "the db2fog:backup:restore rake task is deprecated, use db2fog:restore instead"
      DB2Fog.new.restore
    end

    task :clean => :environment do
      $stderr.puts "the db2fog:backup:clean rake task is deprecated, use db2fog:clean instead"
      DB2Fog.new.clean
    end
  end
end
