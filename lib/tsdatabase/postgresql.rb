
#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  module Postgresql
    class TableError < QueryError; end
    class HashError < QueryError; end
    class HashEmptyError < QueryError; end
  end
end