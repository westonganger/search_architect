# Active Record Search Architect

<a href="https://badge.fury.io/rb/active_record_search_architect" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_record_search_architect.svg" alt="Gem Version"></a>
<a href='https://travis-ci.com/westonganger/active_record_search_architect' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://api.travis-ci.org/westonganger/active_record_search_architect.svg?branch=master' border='0' alt='Build Status' /></a>
<a href='https://rubygems.org/gems/active_record_search_architect' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/active_record_search_architect?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Dead simple, powerful and fully customizable searching for your Rails or ActiveRecord models and associations. Capable of searching any attribute type using SQL type casting.

Why This Library:

Searching requires customizability. This gem's small API and fully understandable design allow you to fully understand how it works. Install this gem and read its code completely OR copy the code straight into your codebase. Know it completely. Now you are free.

If you are considering using [ransack](https://github.com/activerecord-hackery/ransack) then you should think again because `ransack` is a very dirty solution that completely integrates the Searching, Sorting, and Views as requirements of eachother. By not having these features seperated hurts your ability to customize and modify your code. Don't fall into this trap. Use something you fully understand instead.


## Installation

```ruby
gem 'active_record_search_architect'
```

Then add `include SearchArchitect` to your ApplicationRecord or models.

If you want to apply to all models You can create an initializer if the ApplicationRecord model doesnt exist.

```ruby
### Preferred
class ApplicationRecord < ActiveRecord::Base
  include SearchArchitect
end

### OR for individual models

class Post < ActiveRecord::Base
  include SearchArchitect
end

### OR for all models without an ApplicationRecord model

# config/initializers/active_record_search_architect.rb
ActiveSupport.on_load(:active_record) do
  ### Load for all ActiveRecord models
  include SearchArchitect
end
```

## Search Scopes

You can define any search scopes on your model using the following:

```ruby
class Post < ApplicationRecord
  include SearchArchitect::SearchConcern
  
  belongs_to :author, class_name: 'User'

  search_scope :search, attributes: [
    :name,

    "#{self.table.name}.code", ### Plain SQL fully supported

    "CAST(#{self.table_name}.number AS VARCHAR)", # Must convert any non-string fields for searching

    # For any associations, when using a SQL string the table will always be the "association name", not the literal table name, under the hood this is done using SQL aliases.
    author: [:first_name, "author.last_name", "CAST(author.number AS VARCHAR)"],
  ]
  
  search_scope :search_with_locale, required_vars: [:locale], attributes: [
    "#{self.table_name}.name_translations ->> :locale", # specify any variables as symbols, Ex. :locale
  ]
  
  search_scope :search_date_example, attributes: [
    # PostgreSQL, Oracle
    "TO_CHAR(#{self.table_name}.approved_at, 'YYYY-mm-dd')",
    
    # MySQL
    "DATE_FORMAT(#{self.table_name}.approved_at, '%Y-%m-%d')",
    
    # SQLite
    "strftime(#{self.table_name}.approved, '%Y-%m-%d')",
  ]

end
```

You would now have access to the following searching methods:

```ruby
### Multi Word Full-text Search, RECOMMENDED
### Split words on whitespace characters, Quoting is allowed to combine words
posts = Post.search(params[:search])

posts = Post.search_with_locale(params[:search], sql_variables: {locale: @current_locale})
```

## Search Types

### Multi Word Full-text Search - RECOMMENDED
```ruby
posts = Post.search(params[:search], search_type: :multi_search)
### OR
posts = Post.search(params[:search]) # defaults to :multi_search
```

### Full String Search - Considers entire string as one search. 
### In my experience this is the natural choice however the multi-search proves to be more powerful and flexible.
```ruby
posts = Post.search(params[:search], search_type: :full_search)
```

## Comparison Operators

Different comparison operators can be specified by adding the `:comparison_operator` argument

```ruby
posts = Post.search(params[:search], comparison_operator: 'ILIKE')
```

The default is `ILIKE` if Postgresql or `LIKE` if non-postgres.

# SQL Type Casting Cheatsheet

- [docs/sql_type_casting_cheatsheet.md](./docs/sql_type_casting_cheatsheet.md)

# Key Models Provided & Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

- [SearchConcern](./lib/search_architect/concerns/search_scope_concern.rb)

# Search Form / View Example

We do not provide built in view templates because this is a major restriction to applications. Instead we provide an optional simple copy-and-pasteable starter template.

```slim
// ### app/views/shared/_search_form.html.slim

- search_param_name = "search"

- search_text = params[search_param_name]

- search_path = local_assigns[:search_path] || request.path

- back_path = local_assigns[:back_path] || request.path

.table-utilities
  .container-fluid
    .row
      .col-lg-7.col-md-7.col-sm-7.search-field-padding-offset
        form#formSearch.search-form action=search_path method="get" 
          .form-group.has-feedback
            span.input-group
              - if search_text.present?
                span.input-group-btn
                  a.btn.btn-danger href="#{back_path}"  Clear

              input.form-control.input-lg.search-bar autofocus="" name=search_param_name placeholder="Search" type="text" value=search_text

              span.input-group-btn
                button.btn.btn-primary type="submit"
                  i.fal.fa-search
                  | Search
```

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
