############################################################### RUN MIGRATIONS
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

############################################################### SEED
Rails.eager_load!

ApplicationRecord.descendants.each do |klass|
  if !klass.abstract_class
    if klass.connection.adapter_name.downcase.include?('sqlite')
      ActiveRecord::Base.connection.execute("DELETE FROM #{klass.table_name};")
      ActiveRecord::Base.connection.execute("UPDATE `sqlite_sequence` SET `seq` = 0 WHERE `name` = '#{klass.table_name}';")
    else
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{klass.table_name}")
    end
  end
end

Post.find_or_create_by!(title: 1, content: 3)
Post.find_or_create_by!(title: 2, content: 2)
Post.find_or_create_by!(title: 3, content: 2)
Post.find_or_create_by!(title: 4, content: 1)
Post.find_or_create_by!(title: 5, content: 1)

User.find_or_create_by!(name: "foo")
User.find_or_create_by!(name: "bar")

Comment.find_or_create_by!(post_id: 1, content: 3, user_id: 1)
Comment.find_or_create_by!(post_id: 2, content: 2, user_id: 1)
Comment.find_or_create_by!(post_id: 3, content: 2, user_id: 2)
Comment.find_or_create_by!(post_id: 4, content: 1, user_id: 2)
Comment.find_or_create_by!(post_id: 5, content: 1, user_id: 2)
