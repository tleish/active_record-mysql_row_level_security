# ActiveRecord::MysqlRowLevelSecurity

MySQL Row Security for ActiveRecord using MySQL views and MySQL variables.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record-mysql_row_level_security', github: 'com:tleish/active_record-mysql_row_level_security'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mysql_row_level_security 
    
## MySQL Views Setup

Setting up the views for row level security requires 2 steps.

1. Create a MySQL Function to return the value of a variable (since MySQL views to now allow including of variables)

```sql
DROP FUNCTION IF EXISTS my_user_id;
DELIMITER $$
CREATE FUNCTION my_user_id()
RETURNS BIGINT
DETERMINISTIC
BEGIN
  RETURN @my_user_id;
END;
$$
DELIMITER ;
``` 

2. Create a few which uses the function to filter your tables

```sql
DROP VIEW IF EXISTS my_posts_view;
CREATE VIEW my_posts_view AS SELECT * FROM posts WHERE user_id = my_user_id();
```

Do the above for each of the tables you want to replace.

NOTE: If the included table has a schema change, then the view must be rebuilt to pickup the new schema changes.
      
## Usage

Setup the configuration callback in an initializer

```ruby
ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
  configuration.tables = %w[books comments]
  configuration.tables = %w[SELECT] # optional, default is ['SELECT'] queries only
  configuration.sql_variables = {my_user_id: User.current_user.id} 
  configuration.sql_replacement = 'my_\k<table>_view' # `\k<table>` must be included in the string  
end
```

Then at run time the above configuration will run and can be dynamic using application variables, determine your RowIdentityUser used in your SQL Variables and set using the following before any SQL for the Row Security Tables are executed:

The results will be that the SQL variable will be set for a given MySQL session requests and any tables specified will be replaced by their view specifics.

## Error

If an error occurs as a result of the modified SQL, the default behavior is to retry the query using the original/unmodified query.  However, you can add additional error logging/handling by adding the following configuration.
```ruby
ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
  #... 
  configuration.error do |error|
    puts error.message
    raise error
  end
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tleish/active_record-mysql_row_level_security.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
