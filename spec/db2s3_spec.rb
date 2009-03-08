require File.dirname(__FILE__) + '/spec_helper'

describe 'db2s3' do
  def load_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_schema.sql'}' | mysql -u #{DBConfig[:user]} #{DBConfig[:database]}`
  end

  def drop_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_drop_schema.sql'}' | mysql -u #{DBConfig[:user]} #{DBConfig[:database]}`
  end

  class Person < ActiveRecord::Base
  end

  it 'can save and restore a backup to S3' do
    db2s3 = DB2S3.new
    load_schema
    Person.create!(:name => "Baxter")
    db2s3.full_backup
    drop_schema
    db2s3.restore
    Person.find_by_name("Baxter").should_not be_nil
  end

  it 'provides estimated metrics' do
    db2s3 = DB2S3.new
    # 1 GB DB
    db2s3.stub!(:dump_db).and_return(stub("dump file", :size => 1024 * 1024 * 1024))
    metrics = db2s3.metrics
    metrics.should == {
      :storage_cost => 0.15, # 15c/GB-Month rounded up to nearest cent, we're only storing one backup
      :transfer_cost => 3.0, # 10c/GB-Month * 30 backups
      :db_size       => 1024 * 1024 * 1024, # 1 GB
      :total_cost    => 3.17,
      :requests_cost => 0.02,
      :full_backups_per_month => 30 # Default 1 backup/day
    }
  end

  it 'rounds transfer cost metric up to nearest cent' do
    db2s3 = DB2S3.new
    # 1 KB DB
    db2s3.stub!(:dump_db).and_return(stub("dump file", :size => 1024))
    metrics = db2s3.metrics
    metrics[:storage_cost].should == 0.01
    metrics[:transfer_cost].should == 0.01
  end
end
