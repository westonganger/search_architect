class Post < ActiveRecord::Base
  include SearchArchitect

  search_scope :search, attributes: [
    :id,
    :name,
    "(CAST #{table_name}.created_at AS varchar)",
    comments: [
      :content,
      user: [
        "user.id",
        "user.name",
      ]
    ]
  ]

end
