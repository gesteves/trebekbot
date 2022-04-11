class RemoveBotIdFromTeams < ActiveRecord::Migration[7.0]
  def up
    remove_column :teams, :bot_id
  end

  def down
    add_column :teams, :bot_id, :string
  end
end
