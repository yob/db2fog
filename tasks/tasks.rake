namespace :db2s3 do
  namespace :backup do
    desc "Save a full back to S3"
    task :full => :environment do
      DB2S3.new.full_backup
    end

    desc "Restore the latest backup stored on S3"
    task :restore => :environment do
      DB2S3.new.restore
    end
  end
end
