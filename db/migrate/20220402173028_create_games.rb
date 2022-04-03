class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.string :category
      t.string :question
      t.string :answer
      t.integer :value
      t.datetime :air_date
      t.string :ts
      t.string :channel
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
    add_index :games, :ts
    add_index :games, :channel
  end
end
