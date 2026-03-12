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

ActiveRecord::Schema[8.1].define(version: 2026_03_11_105646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "applications", force: :cascade do |t|
    t.string "cover_letter"
    t.datetime "created_at", null: false
    t.bigint "offer_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["offer_id"], name: "index_applications_on_offer_id"
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "offer_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["offer_id"], name: "index_chats_on_offer_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "domain"
    t.string "experience_level"
    t.string "job_type"
    t.integer "salary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "users", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "domain"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "experience_level"
    t.string "first_name"
    t.string "job_type"
    t.string "last_name"
    t.string "preferred_city"
    t.string "preferred_experience_level"
    t.string "preferred_job_type"
    t.integer "preferred_salary"
    t.string "preferred_sector"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "salary"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "applications", "offers"
  add_foreign_key "applications", "users"
  add_foreign_key "chats", "offers"
  add_foreign_key "chats", "users"
  add_foreign_key "messages", "chats"
end
