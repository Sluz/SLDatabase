
require 'tsdatabase' unless defined?( TSDatabase )
require 'pg_jruby'
require 'tsdatabase/tsposgresql'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class JTSPostgresql < TSPostgresql; end
end
