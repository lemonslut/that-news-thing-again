class AddFactualSummaryToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :factual_summary, :text
  end
end
