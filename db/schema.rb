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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_095855) do
  create_table "card_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "ease_factor", default: 2.5, null: false
    t.integer "flashcard_id", null: false
    t.integer "interval", default: 1, null: false
    t.datetime "last_reviewed_at"
    t.datetime "next_review_at"
    t.integer "repetitions", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["flashcard_id"], name: "index_card_progresses_on_flashcard_id"
    t.index ["next_review_at"], name: "index_card_progresses_on_next_review_at"
    t.index ["user_id", "flashcard_id"], name: "index_card_progresses_on_user_id_and_flashcard_id", unique: true
    t.index ["user_id"], name: "index_card_progresses_on_user_id"
  end

  create_table "decks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "language_code"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_decks_on_user_id"
  end

  create_table "flashcards", force: :cascade do |t|
    t.text "back_content", null: false
    t.datetime "created_at", null: false
    t.integer "deck_id", null: false
    t.text "front_content", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["deck_id"], name: "index_flashcards_on_deck_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "card_progresses", "flashcards"
  add_foreign_key "card_progresses", "users"
  add_foreign_key "decks", "users"
  add_foreign_key "flashcards", "decks"
  add_foreign_key "sessions", "users"
end
