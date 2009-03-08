require 'aws/s3'

class DB2S3
  class Config
  end

  def initialize
  end

  def full_backup
    store.store("dump-#{db_credentials[:database]}.sql.gz", open(dump_db.path))
  end

  def restore
    file = store.fetch("dump-#{db_credentials[:database]}.sql.gz")
    run "gunzip -c #{file.path} | mysql #{mysql_options}"
  end

  def metrics
    dump_file = dump_db

    storage_dollars_per_byte_per_month  = 0.15 / 1024.0 / 1024.0 / 1024.0
    transfer_dollars_per_byte_per_month = 0.10 / 1024.0 / 1024.0 / 1024.0
    full_dumps_per_month = 30

    storage_cost = (dump_file.size * storage_dollars_per_byte_per_month * 100).ceil / 100.0
    transfer_cost = (dump_file.size * full_dumps_per_month * transfer_dollars_per_byte_per_month * 100).ceil / 100.0
    requests_cost = 0.02 # TODO: Actually calculate this, with incremental backups could be more

    {
      :db_size       => dump_file.size,
      :storage_cost  => storage_cost,
      :transfer_cost => transfer_cost,
      :total_cost    => storage_cost + transfer_cost + requests_cost,
      :requests_cost => requests_cost,
      :full_backups_per_month => full_dumps_per_month
    }
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
    cmd = " -u#{db_credentials[:user]} "
    cmd += " -p'#{db_credentials[:password]}'" unless db_credentials[:password].nil?
    cmd += " #{db_credentials[:database]}"
  end

  def store
    @store ||= S3Store.new
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

    private

    def bucket
      DB2S3::Config::S3[:bucket]
    end
  end

end
