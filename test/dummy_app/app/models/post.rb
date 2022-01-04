class Post < ActiveRecord::Base
  include SearchArchitect

  has_many :comments
  has_many :foos, class_name: "Comment"

  search_scope :search, attributes: [
    :id,
    :title,
    "CAST(#{table_name}.created_at AS CHAR)",
    comments: [
      :content,
      user: [
        :name,
        "CAST(#{self.connection.quote_table_name("#{table_name}.id")} AS CHAR)", ### when using a SQL string, we have to quote the table_name because `user` is a reserved SQL keyword
      ]
    ]
  ]

end
