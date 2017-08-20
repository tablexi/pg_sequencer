# This module enhances ActiveRecord::SchemaDumper
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/schema_dumper.rb
module PgSequencer
  module SchemaDumper

    def tables(stream)
      super(stream)
      sequences(stream)
    end

    protected

    def sequences(stream)
      sequence_statements = @connection.sequences.map do |sequence|
        statement_parts = [ ("create_sequence ") + sequence.name.inspect ]
        statement_parts << ("increment: " + sequence.options[:increment].inspect)
        statement_parts << ("min: " + sequence.options[:min].inspect)
        statement_parts << ("max: " + sequence.options[:max].inspect)
        statement_parts << ("start: " + sequence.options[:start].inspect)
        statement_parts << ("cache: " + sequence.options[:cache].inspect)
        statement_parts << ("cycle: " + sequence.options[:cycle].inspect)
        statement_parts << ("owned_by: " + sequence.options[:owned_by].inspect)

        "  " + statement_parts.join(", ")
      end

      stream.puts sequence_statements.sort.join("\n")
      stream.puts
    end

  end
end
