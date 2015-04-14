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
            :port: 2424
            :pool: 5
        -
            :adapter: postgresql
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: 5432
            :pool: 6
    :development:
        :database_name_for_sldatabase:
            :adapter: orientdb
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: 2424
            :pool: 4
        :second_database_name_for_sldatabase:
            :adapter: orientdb
            :host: host_name
            :database: database_name
            :username: user_name
            :password: password
            :port: 5432
            :pool: 3
```
JSON
```json
    {
        "production": [
            {
                "adapter": "orientdb",
                "host": "host_name",
                "database": "database_name",
                "username": "user_name",
                "password": "password",
                "port": 2424,
                "pool": 8
            },
            {
                "adapter": "postgresql",
                "host": "host_name",
                "database": "database_name",
                "username": "user_name",
                "password": "password",
                "port": 5432,
                "pool": 4
            }
        ],
        "development": {
            "database_name_for_sldatabase": {
                "adapter": "orientdb",
                "host": "host_name",
                "database": "database_name",
                "username": "user_name",
                "password": "password",
                "port": 2424,
                "pool": 1
            },
            "second_database_name_for_sldatabase": {
                "adapter": "postgresql",
                "host": "host_name",
                "database": "database_name",
                "username": "user_name",
                "password": "password",
                "port": 5432,
                "pool": 2
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
    client = SLDatabase::SLManager.get :database_name_for_sldatabase
    #--- Get Query
    datas = client.find_by_query "select * from Medias limit 2"
    #--- Free client pool
    SLDatabase::SLManager.push :database_name_for_sldatabase
```

## Version
 It is prototype (or alpha) version.


