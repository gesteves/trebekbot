class AddBotIdToTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :bot_id, :string
  end
end
