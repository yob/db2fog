require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'
require 'fog'
require 'tempfile'

class DB2S3
  cattr_accessor :config

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
      ORDER BY total_size_mb + total_index_size_mb desc;
    EOS
    rows = []
    results.each {|x| rows << x.to_a }
    rows
  end

  private

  def dump_db
    dump_file = Tempfile.new("dump")

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
    @store ||= FogStore.new
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

  class FogStore

    def store(remote_filename, io)
      unless directory.files.head(remote_filename)
        directory.files.create(:key => remote_filename, :body => io, :public => false)
      end
    end

    def fetch(remote_filename)
      remote_file = directory.files.get(remote_filename)

      file = Tempfile.new("dump")
      open(file.path, 'w') { |f| f.write(remote_file.body) }
      file
    end

    def list
      directory.files.map { |f| f.key }
    end

    def delete(remote_filename)
      remote_file = remote_file.head(remote_filename)
      remote_file.destroy if remote_file
    end

    private

    def fog_options
      if DB2S3.config.respond_to?(:[])
        DB2S3.config.slice(:aws_access_key_id, :aws_secret_access_key, :provider)
      else
        raise "DB2S3 not configured"
      end
    end

    def directory_name
      if DB2S3.config.respond_to?(:[])
      DB2S3.config[:directory]
      else
        raise "DB2S3 not configured"
      end
    end

    def directory
      @directory ||= storage.directories.get(directory_name)
    end

    def storage
      @storage = Fog::Storage.new(fog_options)
    end
  end

end
