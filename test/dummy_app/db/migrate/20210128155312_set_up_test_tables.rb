class SetUpTestTables < ActiveRecord::Migration::Current

  def change
    create_table :posts do |t|
      t.integer :number
      t.string :name, :code
      t.timestamps
    end
  end

end
