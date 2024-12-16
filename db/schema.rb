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

ActiveRecord::Schema[8.0].define(version: 2024_11_20_200858) do
  create_table "analysis_steps", force: :cascade do |t|
    t.string "type", null: false
    t.binary "analysis_id", limit: 16, null: false
    t.json "input"
    t.json "result"
    t.string "error"
    t.integer "attempt", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_id", "type"], name: "index_analysis_steps_on_analysis_id_and_type"
  end
end
