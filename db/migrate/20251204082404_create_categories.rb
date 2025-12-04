class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :uri, null: false
      t.string :label, null: false
      t.timestamps
    end

    add_index :categories, :uri, unique: true
    add_index :categories, :label
  end
end
