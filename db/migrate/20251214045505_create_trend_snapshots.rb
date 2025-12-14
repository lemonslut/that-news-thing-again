class CreateTrendSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :trend_snapshots do |t|
      t.references :trendable, polymorphic: true, null: false
      t.datetime :period_start, null: false
      t.integer :period_type, null: false, default: 0 # 0=hour, 1=day
      t.integer :article_count, null: false, default: 0
      t.integer :rank
      t.integer :previous_rank
      t.float :velocity, default: 0.0 # change vs previous period
      t.timestamps
    end

    add_index :trend_snapshots, [:trendable_type, :trendable_id, :period_start, :period_type],
              unique: true, name: "idx_trend_snapshots_unique"
    add_index :trend_snapshots, [:period_start, :period_type]
    add_index :trend_snapshots, [:trendable_type, :period_start, :period_type, :rank],
              name: "idx_trend_snapshots_rankings"
  end
end
