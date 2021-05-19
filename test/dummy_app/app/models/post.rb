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
        "user.id",
        "user.name",
      ]
    ]
  ]

end
