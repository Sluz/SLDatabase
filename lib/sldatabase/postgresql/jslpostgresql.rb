
require 'sldatabase' unless defined?( SLDatabase )
require 'pg_jruby'
require 'sldatabase/slposgresql'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class JSLPostgresql < SLPostgresql; end
end
