# Search Architect

<a href="https://badge.fury.io/rb/search_architect" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/search_architect.svg" alt="Gem Version"></a>
<a href='https://github.com/westonganger/search_architect/actions' target='_blank'><img src="https://github.com/westonganger/search_architect/workflows/Tests/badge.svg" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status"></a>
<a href='https://rubygems.org/gems/search_architect' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/search_architect?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Dead simple, powerful and fully customizable searching for your Rails or ActiveRecord models and associations. Capable of searching any attribute type using SQL type casting.

Why This Library:

If you are considering using the `ransack` gem, then you should think again because `ransack` is a very dirty solution that completely integrates the Searching, Sorting, and Views as requirements of eachother. Not having these features separated hurts your ability to customize and modify your code. Don't fall into this trap. This gem is just one concern with one scope. If you want to customize it later you can simply copy the code directly into your project.


# Installation

```ruby
gem 'search_architect'
```

Then add `include SearchArchitect` to your ApplicationRecord or models.

# Defining Search Scopes

You can define any search scopes on your model using the following:

```ruby
class Post < ApplicationRecord
  include SearchArchitect
  
  has_many :comments

  search_scope :search, attributes: [
    :title,
    :content,
    :number, ### non-string fields are automatically converted to a searchable type using sql CAST method
    "CAST((#{self.table.name}.number+100) AS VARCHAR)", ### Plain SQL fully supported
    :created_at, ### automatically converts date/time fields to searchable string type using sql CAST method, uses default db output format by default
    comments: [
      :content,
      author: [
        :first_name, 
        "author.last_name", # Associations SQL table alias always equals the association name, not actual table name
      ],
    ],
  ]
  
  search_scope :search_with_locale, sql_variables: [:locale], attributes: [
    "#{self.table_name}.name_translations ->> :locale", # specify any variables as symbols, Ex. :locale
  ]
  
  search_scope :search_custom_date_format, attributes: [
    # PostgreSQL, Oracle
    "TO_CHAR(#{self.table_name}.approved_at, 'YYYY-mm-dd')",
    
    # MySQL
    "DATE_FORMAT(#{self.table_name}.approved_at, '%Y-%m-%d')",
    
    # SQLite
    "strftime(#{self.table_name}.approved_at, '%Y-%m-%d')",
  ]

end
```

You would now have access to the following searching methods:

```ruby
posts = Post.search(params[:search])

posts = Post.search_with_locale(params[:search], sql_variables: {locale: @current_locale})
```

# Search Types

We includes two different searching types:

### Multi Word Full-text Search

Recommended. Split words on whitespace characters, Quoting is allowed to combine words

The following type of queries are supported:

- `foo` (rows must include foo)
- `foo bar` (rows must include both foo and bar)
- `"foo bar"` (rows must include the phrase "foo bar")

```ruby
posts = Post.search(params[:search], search_type: :multi_search)
### OR
posts = Post.search(params[:search]) # defaults to :multi_search
```

### Full String Search

Considers entire string as one search. In my experience this is the natural choice however the multi-search proves to be very powerful.
```ruby
posts = Post.search(params[:search], search_type: :full_search)
```

# Comparison Operators

Different comparison operators can be specified by adding the `:comparison_operator` argument

```ruby
posts = Post.search(params[:search], comparison_operator: '=')
```

The default is `ILIKE` if Postgresql or `LIKE` if non-postgres. Current valid options are: `ILIKE`, `LIKE`, and `=`

# SQL Type Casting Cheatsheet

- Most Types:
  - `CAST(posts.number AS VARCHAR)`
  - `CAST(posts.created_at AS VARCHAR)` - uses default db output format by default
- Custom Date/Time Formatting:
  - Postgresql, Oracle
    - `TO_CHAR(posts.created_at, 'YYYY-mm-dd')`
  - MySQL
    - `DATE_FORMAT(posts.created_at, '%Y-%m-%d')`
  - SQLite
    `strftime(posts.created_at, '%Y-%m-%d')`

#### Limitation: Boolean columns

Boolean columns are only searched by their true/false value. Searching boolean fields by the column name is not possible because apparently SQL has the restriction where you cannot use `CASE` statements within `WHERE` clauses. 

For example if you were trying to search a `boolean` by the string of its column name:

`CASE WHEN users.admin IS TRUE THEN 'admin' ELSE  '' END`

You will find it extremely difficult to work around this. Instead I strongly recommend handling your booleans filtering logic seperately from your search logic.

# Search Form / Views

We do not provide built in view templates because this is a major restriction to applications. If your looking for starter template feel free to use the following example:

- [examples/_search_form.html.slim](./examples/_search_form.html.slim)


# Key Models Provided & Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

- [lib/search_architect/concerns/search_scope_concern.rb](./lib/search_architect/concerns/search_scope_concern.rb)

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
