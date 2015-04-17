
require 'pg_jruby' if RUBY_PLATFORM =~ /java/
require 'sldatabase/postgresql/slposgresql'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class JSLPostgresql < SLPostgresql; end
end
