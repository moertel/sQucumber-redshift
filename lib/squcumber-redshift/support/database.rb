require_relative '../mock/database'

print 'Connect to production database...'
production_database = PG.connect(
  host: ENV['REDSHIFT_HOST'],
  port: ENV['REDSHIFT_PORT'],
  dbname: ENV['REDSHIFT_DB'],
  user: ENV['REDSHIFT_USER'],
  password: ENV['REDSHIFT_PASSWORD']
)
puts 'DONE.'

TESTING_DATABASE ||= Squcumber::Redshift::Mock::Database.new(production_database)

at_exit do
  TESTING_DATABASE.destroy rescue nil
end
