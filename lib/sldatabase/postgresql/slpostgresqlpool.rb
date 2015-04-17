
require 'jorientdb'
require 'sldatabase/sldatabasepoolmanager'

if RUBY_PLATFORM =~ /java/
  require 'sldatabase/postgresql/jslpostgresql'
else
  require 'sldatabase/postgresql/slpostgresql'
end

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class SLPostgresqlPool < SLDatabasePoolManager
  
    def save_configuration option = {}
      config ||= {}
    
      config[:pool]     = option[:"pool"]     unless option[:"pool"].nil?
      config[:hostaddr] = option[:"host"]     unless option[:"host"].nil?
      config[:port]     = option[:"port"]     unless option[:"port"].nil?
      config[:user]     = option[:"username"] unless option[:"username"].nil?
      config[:password] = option[:"password"] unless option[:"password"].nil?
      config[:dbname]   = option[:"database"] unless option[:"database"].nil?

      # "postgresql://username:password@host:port/database"
      unless (option[:"url"].nil?)
        url = option[:"url"].gsub(/\Apostgresql:\/\//, "")
        url.gsub(/[\w:@\.\-]+/) do |config|
          
          config.gsub(/\A[\w:]+@/) do |user_pass|
            user_pass.gsub(/:[\w\-\.]+/) do |pass|
              config[:password] = pass
              pass = ""
            end
            
            user_pass.gsub(/[\w\-\.]+/) do |user|
              config[:user] = user
              user = ""
            end
            ""
          end
          
          config.gsub(/\A[\w\.]+/) do |host|
            config[:hostaddr] = host
            host = ""
          end
          
          config.gsub(/\d+/) do |port|
            config[:port] = port
            port = ""
          end
        end
        
        url.gsub(/\w+/) do |match|
          config[:dbname] = match
        end
      end
      
     
      self.configuration = config
    end
    
    def process_block
      ->{ SLPostgresql.new PG.connect(configuration), :none }
    end
  end
end