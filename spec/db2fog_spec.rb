require File.dirname(__FILE__) + '/spec_helper'

class Person < ActiveRecord::Base
end

describe DB2Fog do

  let(:storage_dir) { File.join(File.dirname(__FILE__), "storage", "db2fog-test") }

  before(:each) do
    FileUtils.rm_r(storage_dir)    if File.directory?(storage_dir)
    FileUtils.mkdir_p(storage_dir)
  end

  def load_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_schema.sql'}' | mysql -u #{DBConfig[:user]} -p#{DBConfig[:password]} #{DBConfig[:database]}`
  end

  def drop_schema
    `cat '#{File.dirname(__FILE__) + '/mysql_drop_schema.sql'}' | mysql -u #{DBConfig[:user]} -p#{DBConfig[:password]} #{DBConfig[:database]}`
  end

  def backup_files
    Dir.entries(storage_dir).select { |f| f[-3,3] == ".gz"}.sort
  end

  describe "full_backup()" do
    it 'can save a backup' do
      db2fog = DB2Fog.new
      load_schema
      Person.create!(:name => "Baxter")

      Timecop.travel(Time.local(2011, 7, 23, 14, 10, 0)) do
        db2fog.full_backup
      end

      backup_files.should == ["dump-db2s3_unittest-201107230410.sql.gz"]
    end

    it 'can save two backups' do
      db2fog = DB2Fog.new
      load_schema
      Person.create!(:name => "Baxter")

      Timecop.travel(Time.local(2011, 7, 23, 14, 10, 0)) do
        db2fog.full_backup
      end

      Timecop.travel(Time.local(2011, 7, 24, 14, 10, 0)) do
        db2fog.full_backup
      end

      backup_files.should == ["dump-db2s3_unittest-201107230410.sql.gz","dump-db2s3_unittest-201107240410.sql.gz"]
    end
  end

  describe "restore()" do
    it 'can save and restore a backup' do
      db2fog = DB2Fog.new
      load_schema
      Person.create!(:name => "Baxter")
      db2fog.full_backup
      drop_schema
      db2fog.restore
      Person.find_by_name("Baxter").should_not be_nil
    end
  end

  describe "clean()" do
    it 'can remove old backups' do
      db2fog = DB2Fog.new
      load_schema
      Person.create!(:name => "Baxter")

      # keep 1 backup per week
      Timecop.travel(Time.local(2011, 6, 23, 14, 10, 0)) { db2fog.full_backup }
      Timecop.travel(Time.local(2011, 6, 24, 14, 10, 0)) { db2fog.full_backup }

      # keep 1 backup per day
      Timecop.travel(Time.local(2011, 7, 20, 14, 10, 0)) { db2fog.full_backup }
      Timecop.travel(Time.local(2011, 7, 20, 18, 10, 0)) { db2fog.full_backup }
      Timecop.travel(Time.local(2011, 7, 20, 23, 10, 0)) { db2fog.full_backup }

      # keep all backups from past 24 hours
      Timecop.travel(Time.local(2011, 7, 23, 12, 10, 0)) { db2fog.full_backup }
      Timecop.travel(Time.local(2011, 7, 23, 14, 10, 0)) { db2fog.full_backup }

      # clean up
      Timecop.travel(Time.local(2011, 7, 23, 14, 10, 0)) { db2fog.clean }

      backup_files.should == [
        "dump-db2s3_unittest-201106230410.sql.gz",
        "dump-db2s3_unittest-201107200410.sql.gz",
        "dump-db2s3_unittest-201107230210.sql.gz",
        "dump-db2s3_unittest-201107230410.sql.gz"
      ]
    end
  end
end
