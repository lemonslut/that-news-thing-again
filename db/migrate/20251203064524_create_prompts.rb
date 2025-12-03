class CreatePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :prompts do |t|
      t.string :name, null: false
      t.text :body, null: false
      t.integer :version, null: false, default: 1
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :prompts, [:name, :version], unique: true
    add_index :prompts, :active

    add_reference :article_analyses, :prompt, foreign_key: true
  end
end
