if defined?(ActiveRecord::Migration::Current)
  migration_klass = ActiveRecord::Migration::Current
else
  migration_klass = ActiveRecord::Migration
end

class SetUpTestTables < migration_klass

  def change
    create_table :posts do |t|
      t.string :title, :content
      t.integer :number
      t.timestamps
    end

    create_table :comments do |t|
      t.text :content
      t.references :user, :post
      t.timestamps
    end

    create_table :users do |t|
      t.string :name
      t.timestamps
    end
  end

end
