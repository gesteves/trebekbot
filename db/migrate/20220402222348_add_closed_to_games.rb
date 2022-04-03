class AddClosedToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :is_closed, :boolean, default: false
  end
end
