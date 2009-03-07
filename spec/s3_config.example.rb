DB2S3::Config.instance_eval do
  S3 = {
    :access_key_id     => 'yourkey',
    :secret_access_key => 'yoursecretkey',
    :bucket            => 'db2s3_test'
  }
end
