# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_04_11_161732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.string "answer"
    t.boolean "is_correct", default: false
    t.bigint "game_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_answers_on_game_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "category"
    t.string "question"
    t.string "answer"
    t.integer "value"
    t.datetime "air_date"
    t.string "ts"
    t.string "channel"
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_closed", default: false
    t.index ["channel"], name: "index_games_on_channel"
    t.index ["team_id"], name: "index_games_on_team_id"
    t.index ["ts"], name: "index_games_on_ts"
  end

  create_table "teams", force: :cascade do |t|
    t.string "slack_id"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slack_id"], name: "index_teams_on_slack_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_id"
    t.integer "score", default: 0
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slack_id"], name: "index_users_on_slack_id"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "answers", "games"
  add_foreign_key "answers", "users"
  add_foreign_key "games", "teams"
  add_foreign_key "users", "teams"
end
