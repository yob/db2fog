namespace :db2s3 do
  namespace :backup do
    desc "Save a full back to S3"
    task :full => :environment do
      DB2S3.new.full_backup
    end

    desc "Restore your DB from S3"
    task :restore => :environment do
      DB2S3.new.restore
    end

    desc "Keep all backups for the last day, one per day for the last week, and one per week before that. Delete the rest."
    task :clean => :environment do
      DB2S3.new.clean
    end
  end

  desc "Show table sizes for your database"
  task :statistics => :environment do
    # From http://mysqlpreacher.com/wordpress/tag/table-size/
    results = ActiveRecord::Base.connection.execute(<<-EOS)
    SELECT
      engine,
      ROUND(data_length/1024/1024,2) total_size_mb,
      ROUND(index_length/1024/1024,2) total_index_size_mb,
      table_rows,
      table_name article_attachment
      FROM information_schema.tables
      WHERE table_schema = 'rhnh_production'
      ORDER BY 3 desc;
    EOS

    rows = []
    header = [["Type", "Data MB", "Index", "Rows", "Name"], []]
    results.each {|x| rows << x.to_a }
    rows.sort_by {|x| -x[3].to_i }
    puts (header + rows).collect {|x| x.join("\t") }
  end
end
