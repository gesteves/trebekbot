class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :slack_id
      t.string :access_token

      t.timestamps
    end
    add_index :teams, :slack_id
  end
end
