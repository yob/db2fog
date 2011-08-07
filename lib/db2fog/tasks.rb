# coding: utf-8

namespace :db2fog do
  namespace :backup do
    desc "Save a full back to S3"
    task :full => :environment do
      DB2Fog.new.full_backup
    end

    desc "Restore your DB from S3"
    task :restore => :environment do
      DB2Fog.new.restore
    end

    desc "Keep all backups for the last day, one per day for the last week, and one per week before that. Delete the rest."
    task :clean => :environment do
      DB2Fog.new.clean
    end
  end
end
