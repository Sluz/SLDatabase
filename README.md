# SLDatabase

## Installation

Add this line to your application's Gemfile:

    gem 'sldatabase', :git => 'https://github.com/Sluz/SLDatabase.git'

And then execute:

    $ bundle install

Or install it yourself as:
    # Currently not published
    $ gem install sldatabase 

## Configuration file example:
YML
```yml
    :production:
        -
            :adapter: orientdb
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: port_number
            :pool: pool_number
        -
            :adapter: postgresql
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: port_number
            :pool: pool_number
    :development
        :database_name_for_sldatabase:
            :adapter: orientdb
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: port_number
            :pool: pool_number
        :second_database_name_for_sldatabase:
            :adapter: orientdb
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: port_number
            :pool: pool_number
```
JSON
```json
    {
        "production": [
            {
                "adapter": "orientdb"
                "host":" host_name"
                "database": "database_name"
                "username": "user_name"
                "password": "password"
                "port": port_number
                "pool": pool_number
            },
            {
                "adapter": "postgresql"
                "host": "host_name"
                "database": "database_name"
                "username": "user_name"
                "password": "password"
                "port": port_number
                "pool": pool_number
            }
        ]
        "development": {
            "database_name_for_sldatabase": {
                "adapter": "orientdb"
                "host":" host_name"
                "database": "database_name"
                "username": "user_name"
                "password": "password"
                "port": port_number
                "pool": pool_number
            },
            "second_database_name_for_sldatabase": {
                "adapter": "postgresql"
                "host": "host_name"
                "database": "database_name"
                "username": "user_name"
                "password": "password"
                "port": port_number
                "pool": pool_number
            }
        }
    }
```
## Usage

```ruby
    require 'sldatabase'
    #--- Loading Configuration
    SLDatabase.load_configuration('configuration_file_path', :production)

    #--- Get client pool
    client = LDatabase::SLManager.get :jsonstore
    #--- Get Query
    datas = client.find_by_query "select * from Medias limit 2"
    #--- Free client pool
    LDatabase::SLManager.push :jsonstore
```

## Version
 It is prototype (or alpha) version.


