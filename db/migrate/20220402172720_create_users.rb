class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :slack_id
      t.integer :score, default: 0
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
    add_index :users, :slack_id
  end
end
