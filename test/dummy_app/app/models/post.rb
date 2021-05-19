class Post < ActiveRecord::Base
  include SearchArchitect

  has_many :comments

  search_scope :search, attributes: [
    :id,
    :title,
    "CAST(#{table_name}.created_at AS varchar)",
    comments: [
      :content,
      user: [
        :name,
        "CAST(#{self.connection.quote_table_name("#{table_name}.id")} AS varchar)", ### when using a SQL string, we have to quote the table_name because `user` is a reserved SQL keyword
      ]
    ]
  ]

end
