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
  create_table "analysis_language_detections", force: :cascade do |t|
    t.string "language"
    t.string "provider", default: "openai", null: false
    t.string "model", default: "gpt-4o-mini", null: false
    t.float "temperature", default: 0.0, null: false
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.binary "report_id", limit: 16, null: false
    t.index ["report_id"], name: "index_analysis_language_detections_on_report_id"
  end

  create_table "analysis_steps", force: :cascade do |t|
    t.string "type"
    t.json "result"
    t.string "provider", default: "openai", null: false
    t.string "model", default: "gpt-4o-mini", null: false
    t.float "temperature", default: 0.0, null: false
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.binary "report_id", limit: 16, null: false
    t.index ["report_id"], name: "index_analysis_steps_on_report_id"
    t.index ["type", "report_id"], name: "index_analysis_steps_on_type_and_report_id"
  end

  create_table "reports", id: { type: :binary, limit: 16 }, force: :cascade do |t|
    t.string "query", null: false
    t.json "advanced_settings"
    t.integer "status", default: 0
    t.integer "progress_percent", default: 0
    t.json "progress_details", default: []
    t.json "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_reports_on_created_at"
    t.index ["owner_type", "owner_id", "created_at"], name: "index_reports_on_owner_and_created_at"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "results", force: :cascade do |t|
    t.json "json"
    t.binary "report_id", limit: 16, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_results_on_report_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "analysis_language_detections", "reports"
  add_foreign_key "analysis_steps", "reports"
  add_foreign_key "results", "reports"
end
