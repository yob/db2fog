require 'aws/s3'

class DB2S3
  class Config
  end

  def initialize
  end

  def full_backup
    dump_file = Tempfile.new("dump")
    
    #cmd = "mysqldump --quick --single-transaction --create-options -u#{db_credentials[:user]} --flush-logs --master-data=2 --delete-master-logs"
    cmd = "mysqldump --quick --single-transaction --create-options #{mysql_options}"
    cmd += " | gzip > #{dump_file.path}"
    run(cmd)
 
    store.store("dump-#{db_credentials[:database]}.sql.gz", open(dump_file.path))
  end

  def restore
    file = store.fetch("dump-#{db_credentials[:database]}.sql.gz")
    run "gunzip -c #{file.path} | mysql #{mysql_options}"
  end

  def mysql_credentials
    cmd = " -u#{db_credentials[:user]} "
    cmd += " -p'#{db_credentials[:password]}'" unless db_credentials[:password].nil?
    cmd += " #{db_credentials[:database]}"
  end

  private

  def store
    @store ||= S3Store.new
  end

  def run(command)
    puts command
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

    private

    def bucket
      DB2S3::Config::S3[:bucket]
    end
  end

end
