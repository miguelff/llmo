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

ActiveRecord::Schema[8.0].define(version: 2024_11_07_200855) do
  create_table "reports", id: { type: :binary, limit: 16 }, force: :cascade do |t|
    t.string "query", null: false
    t.json "advanced_settings"
    t.integer "status", default: 0
    t.integer "progress_percent", default: 0
    t.json "progress_details", default: []
    t.json "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reports_on_created_at"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "results", force: :cascade do |t|
    t.json "json"
    t.binary "report_id", limit: 16, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_results_on_report_id"
  end

  add_foreign_key "results", "reports"
end