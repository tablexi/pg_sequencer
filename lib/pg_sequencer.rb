require "active_record"
require "active_support"

require "pg_sequencer/version"
require "pg_sequencer/connection_adapters/postgresql_adapter"
require "pg_sequencer/sequence_definition"
require "pg_sequencer/schema_dumper"

require "pg_sequencer/railtie" if defined?(Rails)

begin
  require "pry"
rescue LoadError
end

module PgSequencer
end

