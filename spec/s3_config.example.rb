DB2Fog.config = {
  :aws_access_key_id     => 'yourkey',
  :aws_secret_access_key => 'yoursecretkey',
  :directory             => 'db2fog-test',
  :provider              => 'AWS'
}

DBConfig = {
  :adapter  => "mysql2",
  :encoding => "utf8",
  :database => 'db2s3_unittest',
  :user     => "username",
  :password => "password"
}
