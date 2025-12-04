class CreateConcepts < ActiveRecord::Migration[8.0]
  def change
    create_table :concepts do |t|
      t.string :uri, null: false
      t.string :concept_type, null: false
      t.string :label, null: false
      t.timestamps
    end

    add_index :concepts, :uri, unique: true
    add_index :concepts, :concept_type
    add_index :concepts, :label
  end
end
