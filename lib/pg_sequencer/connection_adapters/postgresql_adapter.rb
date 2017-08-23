# This module enhances ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
module PgSequencer
  module ConnectionAdapters
    module PostgreSQLAdapter

      # Example usage:
      #
      #   create_sequence "user_seq",
      #     increment: 1,
      #     min: (1|false),
      #     max: (20000|false),
      #     start: 1,
      #     cache: 5,
      #     cycle: true,
      #     owned_by: ("table_name.column_name"|"NONE"|nil),
      def create_sequence(name, options = {})
        execute create_sequence_sql(name, options)
      end

      # Example usage:
      #
      #   change_sequence "user_seq",
      #     increment: 1,
      #     min: (1|false),
      #     max: (20000|false),
      #     restart: 1,
      #     cache: 5,
      #     cycle: true,
      #     owned_by: ("table_name.column_name"|"NONE"|nil),
      def change_sequence(name, options = {})
        execute change_sequence_sql(name, options)
      end

      def drop_sequence(name)
        execute drop_sequence_sql(name)
      end

      # Example SQL:
      #
      #   CREATE [ TEMPORARY | TEMP ] SEQUENCE [ IF NOT EXISTS ] name [ INCREMENT [ BY ] increment ]
      #     [ MINVALUE minvalue | NO MINVALUE ] [ MAXVALUE maxvalue | NO MAXVALUE ]
      #     [ START [ WITH ] start ] [ CACHE cache ] [ [ NO ] CYCLE ]
      #     [ OWNED BY { table_name.column_name | NONE } ]
      def create_sequence_sql(name, options = {})
        options.delete(:restart)
        "CREATE SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      # Example SQL:
      #
      #   ALTER SEQUENCE [ IF EXISTS ] name [ INCREMENT [ BY ] increment ]
      #     [ MINVALUE minvalue | NO MINVALUE ] [ MAXVALUE maxvalue | NO MAXVALUE ]
      #     [ START [ WITH ] start ]
      #     [ RESTART [ [ WITH ] restart ] ]
      #     [ CACHE cache ] [ [ NO ] CYCLE ]
      #     [ OWNED BY { table_name.column_name | NONE } ]
      def change_sequence_sql(name, options = {})
        return "" if options.blank?
        options.delete(:start)
        "ALTER SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      def drop_sequence_sql(name)
        "DROP SEQUENCE #{name}"
      end

      def sequence_options_sql(options = {})
        sql = ""
        sql << increment_option_sql(options) if options[:increment] or options[:increment_by]
        sql << min_option_sql(options)
        sql << max_option_sql(options)
        sql << start_option_sql(options) if options[:start]    or options[:start_with]
        sql << restart_option_sql(options) if options[:restart]  or options[:restart_with]
        sql << cache_option_sql(options) if options[:cache]
        sql << cycle_option_sql(options)
        # sql << owned_option_sql(options) if options[:owned_by]
        sql
      end

      # Values for a selected sequence:
      # --------------+--------------------
      # sequence_name | temp
      # last_value    | 7
      # start_value   | 1
      # increment_by  | 1
      # max_value     | 9223372036854775807
      # min_value     | 1
      # cache_value   | 1
      # log_cnt       | 26
      # is_cycled     | f
      # is_called     | t
      def sequences
        all_sequences = []

        select_sequence_names.each do |sequence_name|

          row = select_one("SELECT * FROM #{sequence_name}")
          # owner = select_sequence_owner(sequence_name)

          options = {
            increment: row["increment_by"].to_i,
            min: row["min_value"].to_i,
            max: row["max_value"].to_i,
            start: row["start_value"].to_i,
            cache: row["cache_value"].to_i,
            cycle: row["is_cycled"] == "t",
            # owned_by: owner ? "#{owner["refobjid"]}.#{owner["attname"]}" : nil
          }

          all_sequences << SequenceDefinition.new(sequence_name, options)
        end

        all_sequences
      end

      protected

      # Values for all sequences:
      # --------------+--------------------
      # relname       | some_seq
      def select_sequence_names
        sql = <<-SQL.strip_heredoc
              SELECT c.relname FROM pg_class c
              WHERE c.relkind = 'S' ORDER BY c.relname ASC
              SQL

        select_all(sql).map { |row| row["relname"] }
      end

      # Values for owner of a sequence:
      # --------------+--------------------
      # refobjid      | some_table
      # attname       | some_column
      def select_sequence_owner(sequence_name)
        sql = <<-SQL.strip_heredoc
              SELECT d.refobjid::regclass, a.attname
              FROM pg_depend d
              JOIN pg_attribute a ON a.attrelid = d.refobjid
              AND a.attnum = d.refobjsubid
              WHERE d.objid = 'public."#{sequence_name}"'::regclass
              AND d.refobjsubid > 0
              SQL

        select_one(sql)
      end

      def increment_option_sql(options = {})
        " INCREMENT BY #{options[:increment] || options[:increment_by]}"
      end

      def min_option_sql(options = {})
        case options[:min]
        when nil then ""
        when false then " NO MINVALUE"
        else " MINVALUE #{options[:min]}"
        end
      end

      def max_option_sql(options = {})
        case options[:max]
        when nil then ""
        when false then " NO MAXVALUE"
        else " MAXVALUE #{options[:max]}"
        end
      end

      def restart_option_sql(options = {})
        " RESTART WITH #{options[:restart] || options[:restart_with]}"
      end

      def start_option_sql(options = {})
        " START WITH #{options[:start] || options[:start_with]}"
      end

      def cache_option_sql(options = {})
        " CACHE #{options[:cache]}"
      end

      def cycle_option_sql(options = {})
        case options[:cycle]
        when nil then ""
        when false then " NO CYCLE"
        else " CYCLE"
        end
      end

      def owned_option_sql(options = {})
        " OWNED BY #{options[:owned_by]}"
      end

    end
  end
end
