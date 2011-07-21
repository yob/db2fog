require File.dirname(__FILE__) + '/spec_helper'

class Person < ActiveRecord::Base
end

describe DB2Fog do

  before(:all) do
    storage_dir = File.dirname(__FILE__) + "/storage"
    Dir.mkdir(storage_dir) unless File.directory?(storage_dir)
    bucket = File.join(storage_dir, "db2s3-test")
    Dir.mkdir(bucket) unless File.directory?(bucket)
  end

  def load_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_schema.sql'}' | mysql -u #{DBConfig[:user]} -p#{DBConfig[:password]} #{DBConfig[:database]}`
  end

  def drop_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_drop_schema.sql'}' | mysql -u #{DBConfig[:user]} -p#{DBConfig[:password]} #{DBConfig[:database]}`
  end

  it 'can save and restore a backup to S3' do
    db2fog = DB2Fog.new
    load_schema
    Person.create!(:name => "Baxter")
    db2fog.full_backup
    drop_schema
    db2fog.restore
    Person.find_by_name("Baxter").should_not be_nil
  end
end
