#  Tapastreet ltd 
#  All right reserved 
#

require 'activerecord-jdbcpostgresql-adapter'
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class JTSPostgresql < TSClientdb
    def initialize option={}
      @dbconfig = {
        :username => option["username"],
        :password => option["password"],
        :database => option["database"]
      }
      
       if (option["url"].nil?)
        if (option["port"].nil?)
          @dbconfig[:url] = "jdbc:postgres://#{ option["username"] }:#{ option["password"] }@#{ option["host"] }/#{ option["database"] }"
        else
          @dbconfig[:url] = "jdbc:postgres://#{ option["username"] }:#{ option["password"] }@#{ option["host"] }:#{ option["port"] }/#{ option["database"] }"
        end
      else 
        @dbconfig[:url] = "jdbc:"+option["url"]
      end
    end
  end
end
