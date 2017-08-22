# pg_sequencer

[![Build Status](https://travis-ci.org/tablexi/pg_sequencer.svg?branch=master)](https://travis-ci.org/tablexi/pg_sequencer)

pg_sequencer adds methods to your migrations to allow you to create, drop and change sequence objects in PostgreSQL. It also dumps sequences to schema.rb.

This is especially useful if you are connecting to a legacy database where the primary key field is declared as an INTEGER and a sequence is queried for the value of the next record.

The design of pg_sequencer is heavily influenced on Matthew Higgins' Foreigner gem: https://github.com/matthuhiggins/foreigner


## Installation

Requires `ruby` version 2.3+.

Add this to your Gemfile:

    gem 'pg_sequencer'


## API

pg_sequencer adds the following methods to migrations:

```
create_sequence(sequence_name, options)
change_sequence(sequence_name, options)
drop_sequence(sequence_name)
```

The methods closely mimic the syntax of the PostgreSQL SQL for `CREATE SEQUENCE`, `DROP SEQUENCE` and `ALTER SEQUENCE`. See the *REFERENCES* section below for more information.


## Options

For `create_sequence` and `change_sequence`, all options are the same, except `create_sequence` will look for `:start` or `:start_with`, and
`change_sequence` will look for `:restart` or `:restart_with`.

* `:increment`/`:increment_by` (integer) - The value to increment the sequence by.
* `:min` (integer/false) - The minimum value of the sequence. If specified as false (e.g. :min => false), "NO MINVALUE" is sent to Postgres.
* `:max` (integer/false) - The maximum value of the sequence. May be specified as ":max => false" to generate "NO MAXVALUE"
* `:start`/`:start_with` (integer) - The starting value of the sequence (**create_sequence** only)
* `:restart`/`:restart_with` (integer) The value to restart the sequence with (**change_sequence** only)
* `:cache` (integer) - The number of values the sequence should cache.
* `:cycle` (boolean) - Whether the sequence should cycle. Generated at "CYCLE" or "NO CYCLE"


## Examples


### Creating a sequence

Create a sequence called `user_seq`, incrementing by 1, min of 1, max of 2000000, starts at 1, caches 10 values, and disallows cycles:

    create_sequence "user_seq",
      increment: 1,
      min: 1,
      max: 2000000,
      start: 1,
      cache: 10,
      cycle: false

This is equivalent of the following query:

    CREATE SEQUENCE user_seq INCREMENT BY 1 MIN 1 MAX 2000000 START 1 CACHE 10 NO CYCLE


### Reset a sequence's value:

    change_sequence "accounts_seq", :restart_with => 50

This is equivalent to:

    ALTER SEQUENCE accounts_seq RESTART WITH 50


### Removing a sequence:

    drop_sequence "products_seq"


## Caveats / Bugs

* Tested with postgres 9.0.4, should work down to 8.1.
* Listing all the sequences in a database creates n+1 queries (1 to get the names and n to describe each sequence). Is there a way to fully describe all sequences in a database in one query?
* The "SET SCHEMA" fragment of the ALTER command is not implemented.
* Oracle/other databases not supported
* Other unknown bugs :)


## References

* http://www.postgresql.org/docs/8.1/static/sql-createsequence.html
* http://www.postgresql.org/docs/8.1/static/sql-altersequence.html
* http://www.alberton.info/postgresql_meta_info.html
