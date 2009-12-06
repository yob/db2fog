require 'activesupport'
require 'aws/s3'
require 'tempfile'

class DB2S3
  class Config
  end

  def initialize
  end

  def full_backup
    file_name = "dump-#{db_credentials[:database]}-#{Time.now.utc.strftime("%Y%m%d%H%M")}.sql.gz"
    store.store(file_name, open(dump_db.path))
    store.store(most_recent_dump_file_name, file_name)
  end

  def restore
    dump_file_name = store.fetch(most_recent_dump_file_name).read
    file = store.fetch(dump_file_name)
    run "gunzip -c #{file.path} | mysql #{mysql_options}"
  end

  # TODO: This method really needs specs
  def clean
    to_keep = []
    filelist = store.list
    files = filelist.reject {|file| file.ends_with?(most_recent_dump_file_name) }.collect do |file|
      {
        :path => file,
        :date => Time.parse(file.split('-').last.split('.').first)
      }
    end
    # Keep all backups from the past day
    files.select {|x| x[:date] >= 1.day.ago }.each do |backup_for_day|
      to_keep << backup_for_day
    end

    # Keep one backup per day from the last week
    files.select {|x| x[:date] >= 1.week.ago }.group_by {|x| x[:date].strftime("%Y%m%d") }.values.each do |backups_for_last_week|
      to_keep << backups_for_last_week.sort_by{|x| x[:date].strftime("%Y%m%d") }.first
    end

    # Keep one backup per week since forever
    files.group_by {|x| x[:date].strftime("%Y%W") }.values.each do |backups_for_week|
      to_keep << backups_for_week.sort_by{|x| x[:date].strftime("%Y%m%d") }.first
    end

    to_destroy = filelist - to_keep.uniq.collect {|x| x[:path] }
    to_destroy.delete_if {|x| x.ends_with?(most_recent_dump_file_name) }
    to_destroy.each do |file|
      store.delete(file.split('/').last)
    end
  end

  def statistics
      # From http://mysqlpreacher.com/wordpress/tag/table-size/
    results = ActiveRecord::Base.connection.execute(<<-EOS)
    SELECT
      engine,
      ROUND(data_length/1024/1024,2) total_size_mb,
      ROUND(index_length/1024/1024,2) total_index_size_mb,
      table_rows,
      table_name article_attachment
      FROM information_schema.tables
      WHERE table_schema = '#{db_credentials[:database]}'
      ORDER BY 3 desc;
    EOS
    rows = []
    results.each {|x| rows << x.to_a }
    rows
  end

  private

  def dump_db
    dump_file = Tempfile.new("dump")

    #cmd = "mysqldump --quick --single-transaction --create-options -u#{db_credentials[:user]} --flush-logs --master-data=2 --delete-master-logs"
    cmd = "mysqldump --quick --single-transaction --create-options #{mysql_options}"
    cmd += " | gzip > #{dump_file.path}"
    run(cmd)

    dump_file
  end

  def mysql_options
    cmd = ''
    cmd += " -u #{db_credentials[:username]} " unless db_credentials[:username].nil?
    cmd += " -p'#{db_credentials[:password]}'" unless db_credentials[:password].nil?
    cmd += " -h '#{db_credentials[:host]}'"    unless db_credentials[:host].nil?
    cmd += " #{db_credentials[:database]}"
  end

  def store
    @store ||= S3Store.new
  end

  def most_recent_dump_file_name
    "most-recent-dump-#{db_credentials[:database]}.txt"
  end

  def run(command)
    result = system(command)
    raise("error, process exited with status #{$?.exitstatus}") unless result
  end

  def db_credentials
    ActiveRecord::Base.connection.instance_eval { @config } # Dodgy!
  end

  class S3Store
    def initialize
      @connected = false
    end

    def ensure_connected
      return if @connected
      AWS::S3::Base.establish_connection!(DB2S3::Config::S3.slice(:access_key_id, :secret_access_key).merge(:use_ssl => true))
      AWS::S3::Bucket.create(bucket)
      @connected = true
    end

    def store(file_name, file)
      ensure_connected
      AWS::S3::S3Object.store(file_name, file, bucket)
    end

    def fetch(file_name)
      ensure_connected
      AWS::S3::S3Object.find(file_name, bucket)

      file = Tempfile.new("dump")
      open(file.path, 'w') do |f|
        AWS::S3::S3Object.stream(file_name, bucket) do |chunk|
          f.write chunk
        end
      end
      file
    end

    def list
      ensure_connected
      AWS::S3::Bucket.find(bucket).objects.collect {|x| x.path }
    end

    def delete(file_name)
      if object = AWS::S3::S3Object.find(file_name, bucket)
        object.delete
      end
    end

    private

    def bucket
      DB2S3::Config::S3[:bucket]
    end
  end

end
